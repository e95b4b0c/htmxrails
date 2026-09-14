# Pin npm packages by running ./bin/importmap

pin "application"

# htmx 2.0.10's ESM build, vendored in vendor/javascript. Pinning it is what lets
# app/javascript/application.js say `import htmx from "htmx"` — the bare specifier
# is resolved to the digested asset below.
# 经典构建不能当模块 import:它的 var htmx = (function(){...})() 在模块作用域里是模块局部变量,不会挂到 window,
# 于是 application.js 里的 htmx.config.responseHandling = ... 会直接 ReferenceError(而 htmx 自身仍会偷偷跑起来,这种半坏状态最难查)。
# ESM 构建 export default htmx,自初始化(内部有 DOMContentLoaded 就绪逻辑),且无内部 import,正好适用。
pin "htmx", to: "htmx.esm.js"

# Nothing else is mapped: no Turbo, no Stimulus.
