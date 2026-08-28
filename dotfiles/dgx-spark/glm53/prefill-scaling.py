#!/usr/bin/env python3
"""TTFT vs prompt length -> separates fixed per-request cost from marginal prefill."""
import json, time, urllib.request, random

H, P, M = "127.0.0.1", 8888, "glm-5.3-flash"

def ttft(prompt_tokens):
    # unique filler so prefix caching cannot serve it
    nonce = random.randint(1, 10**12)
    words = " ".join(f"item{nonce}x{i} value {i*7%97} tag alpha beta"
                     for i in range(prompt_tokens // 8))
    body = {"model": M,
            "messages": [{"role": "user", "content": f"[{nonce}]\n{words}\nReply with just: K"}],
            "max_tokens": 1, "temperature": 0.0,
            "chat_template_kwargs": {"enable_thinking": False}}
    req = urllib.request.Request(f"http://{H}:{P}/v1/chat/completions",
        data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    t0 = time.perf_counter()
    r = json.load(urllib.request.urlopen(req, timeout=600))
    dt = time.perf_counter() - t0
    return r["usage"]["prompt_tokens"], dt

print(f"{'prompt tok':>11} {'TTFT s':>8} {'tok/s':>9} {'chunks@2048':>12}")
print("-" * 45)
pts = []
for target in (500, 2000, 4000, 8000, 16000, 32000):
    n, dt = ttft(target)
    pts.append((n, dt))
    print(f"{n:>11,} {dt:>8.2f} {n/dt:>9.0f} {-(-n//2048):>12}")

# linear fit: t = fixed + n/rate
import statistics
xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
mx, my = statistics.mean(xs), statistics.mean(ys)
slope = sum((x-mx)*(y-my) for x, y in pts) / sum((x-mx)**2 for x in xs)
fixed = my - slope*mx
print()
print(f"fit: TTFT = {fixed:.2f}s fixed + prompt/{1/slope:,.0f} tok/s marginal")
print(f"     fixed cost is {fixed/(fixed+32000*slope)*100:.0f}% of a 32K prefill")
