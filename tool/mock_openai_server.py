"""最小 OpenAI 兼容服务，用于在没有真实 API Key 时验证 Toki 的 AI 链路。

用法：
    python tool/mock_openai_server.py 11434
    # Android 模拟器：把端口转发进去，然后在设置里用 Base URL http://127.0.0.1:11434/v1
    adb reverse tcp:11434 tcp:11434

行为：
  * POST /v1/chat/completions，stream=false → 一次性返回完整回复
  * stream=true → 按 SSE 逐块返回（每块间隔 0.35 秒），用于验证"逐字输出"
  * GET /v1/models → 返回一个假模型名
"""
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 11434

CHUNKS = [
    "主人，",
    "今天你有 ",
    "3 个安排：",
    "15:00 毕业设计答辩，",
    "20:00 课程项目截止。",
]

# 让 mock 也能演示"工具调用"：如果请求里带了 tools 且还没有工具结果，
# 就先请求调用 create_event；拿到工具结果后再给出最终回复。
TOOL_CALL_ARGS = {
    "title": "毕业答辩（AI 创建）",
    "start_time": "2026-10-20T15:00:00",
    "reminder_minutes": 30,
}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _json(self, payload, status=200):
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.endswith("/models"):
            self._json({"object": "list", "data": [{"id": "mock-model"}]})
        else:
            self._json({"error": "not found"}, 404)

    def do_POST(self):
        length = int(self.headers.get("content-length", 0))
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw or b"{}")
        except json.JSONDecodeError:
            body = {}
        stream = bool(body.get("stream"))
        messages = body.get("messages") or []
        has_tool_result = any(m.get("role") == "tool" for m in messages)
        wants_tool_call = bool(body.get("tools")) and not has_tool_result
        system_messages = [m for m in messages if m.get("role") == "system"]
        context_chars = (
            len(system_messages[-1].get("content", "")) if system_messages else 0
        )
        sys.stderr.write(
            "REQ path=%s stream=%s model=%s auth=%s tools=%s tool_result=%s "
            "system_msgs=%d context_chars=%d\n"
            % (
                self.path,
                stream,
                body.get("model"),
                "yes" if self.headers.get("authorization") else "no",
                "yes" if body.get("tools") else "no",
                "yes" if has_tool_result else "no",
                len(system_messages),
                context_chars,
            )
        )
        sys.stderr.flush()

        if stream:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.end_headers()
            if wants_tool_call:
                payload = {
                    "choices": [
                        {
                            "delta": {
                                "tool_calls": [
                                    {
                                        "index": 0,
                                        "id": "call_mock_1",
                                        "type": "function",
                                        "function": {
                                            "name": "create_event",
                                            "arguments": json.dumps(
                                                TOOL_CALL_ARGS, ensure_ascii=False
                                            ),
                                        },
                                    }
                                ]
                            }
                        }
                    ]
                }
                line = "data: %s\n\n" % json.dumps(payload, ensure_ascii=False)
                self.wfile.write(line.encode("utf-8"))
                self.wfile.flush()
                time.sleep(0.3)
                final = {
                    "choices": [{"delta": {}, "finish_reason": "tool_calls"}]
                }
                self.wfile.write(
                    ("data: %s\n\n" % json.dumps(final)).encode("utf-8")
                )
                self.wfile.flush()
                self.wfile.write(b"data: [DONE]\n\n")
                self.wfile.flush()
                return
            for chunk in CHUNKS:
                payload = {"choices": [{"delta": {"content": chunk}}]}
                line = "data: %s\n\n" % json.dumps(payload, ensure_ascii=False)
                self.wfile.write(line.encode("utf-8"))
                self.wfile.flush()
                time.sleep(0.35)
            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
            return

        self._json(
            {
                "choices": [
                    {
                        "message": {
                            "role": "assistant",
                            "content": "".join(CHUNKS),
                        },
                        "finish_reason": "stop",
                    }
                ]
            }
        )

    def log_message(self, fmt, *args):
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    sys.stderr.write("mock openai listening on %d\n" % PORT)
    sys.stderr.flush()
    server.serve_forever()
