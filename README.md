# HTMX on Rails

一个用于演示 [htmx gem](https://alchemists.io/projects/htmx) 的 Rails 8.1 应用:
**一个主页面框架 + 若干由 htmx 动态加载的子页面**,没有前端构建步骤,没有客户端状态。

## 运行

本机没有全局 `ruby`,所有 Ruby 命令都走 [rv](https://rv.dev):

```bash
export PATH="$HOME/.cargo/bin:$PATH"

rv run bundle install
rv run bin/rails server          # http://localhost:3000
```

其他常用命令:

```bash
rv run bin/rails test            # 9 个请求层测试
rv run bin/rubocop               # 代码风格
rv run bin/rails console
```

## 页面结构

| 路由 | 说明 |
| --- | --- |
| `GET /` | Home:框架说明 + 服务器时钟轮询演示 |
| `GET /about` | About:htmx gem 的 API 与实现说明 |
| `GET /contact` | Contact:htmx 表单 + 服务端校验 |
| `POST /contact` | 表单提交:`422` 原地渲染错误 / `200` 换成成功卡片 |
| `GET /clock` | 被首页时钟组件每 2 秒轮询一次的片段 |

每个页面 **既能整页渲染,也能只返回片段**,取决于请求里有没有 `HX-Request` 头:

* 直接访问 / 刷新 / 收藏夹 → 完整 HTML(带 header、导航、footer)
* 点击标签页 → 只有 `<main id="main-content">` 里要替换的那段 HTML

URL 通过 `hx-push-url` 同步,所以每个标签页同时也是一个真实的、可收藏的 Rails 路由。

## 演示脚本(照着点)

1. **点 About / Contact 标签** — 地址栏变化,内容区域替换,页面没有刷新。
   打开开发者工具的 Network 面板:响应体里只有片段,没有 `<html>`/`<head>`。
   注意标签高亮和浏览器标签页标题也变了 —— 导航条和 `<title>` 是通过
   `hx-swap-oob` 带回来的,而不是整页重绘。
2. **刷新浏览器** — 同一个 URL 返回完整页面,htmx 只是渐进增强。
3. **Contact 表单留空提交** — 服务端返回 `422`,错误信息原地渲染;
   填对再提交 — 换成成功卡片,右下角弹出 toast。
4. **看首页的时钟** — 每 2 秒一次请求,request id 每次都在变。
5. **看 Network 的响应头** — 成功提交时带 `HX-Trigger`,时钟每次都是新的请求。

## htmx gem 用在哪

```ruby
# 1. 构建属性:snake_case 进,dashed + prefix 出
HTMX[get: "/about", target: "#main-content", push_url: true]
# => {"data-hx-get" => "/about", "data-hx-target" => "#main-content", "data-hx-push-url" => true}

# 2. 解析请求头,判断这是不是一个 htmx 请求(app/controllers/application_controller.rb)
HTMX.request(**request.headers.env).request?

# 3. 写响应头(app/controllers/concerns/htmx_responses.rb)
htmx_response trigger: { "contact:message-sent" => { name: @message.name } }.to_json
# => HX-Trigger: {"contact:message-sent":{"name":"Ada"}}
```

`HTMX[...]` 默认生成 `data-hx-*` 前缀(htmx 同时支持 `hx-*` 和 `data-hx-*`,
前者是自定义属性,后者是合法 HTML5);想换成 `hx-*` 就用
`HTMX::Prefixer.new("hx")`。

## 关键文件

```
app/views/layouts/application.html.erb   主框架:topbar + 导航 + <main id="main-content">
app/views/shared/_nav.html.erb           标签页;htmx 请求时额外带 hx-swap-oob
app/controllers/pages_controller.rb      整页/片段二选一,表单提交
app/controllers/application_controller.rb HTMX.request 封装 + htmx_request?
app/controllers/concerns/htmx_responses.rb HTMX.response! 封装
app/helpers/application_helper.rb        page_nav / nav_link / body 级 CSRF 头
app/helpers/code_sample_helper.rb        页面上展示的代码片段
app/views/pages/_clock.html.erb          每 2 秒自替换的轮询片段
app/views/pages/_contact_card.html.erb   表单卡片(422 时原样返回,带错误)
app/javascript/application.js            唯一的 JS 入口:import htmx、422 交换配置、HX-Trigger → toast
config/importmap.rb                      把 "htmx" 映射到 vendor/javascript/htmx.esm.js
vendor/javascript/htmx.esm.js            htmx 2.0.10 的 ESM 构建
test/controllers/pages_controller_test.rb 请求层断言(片段、OOB、422、HX-Trigger、importmap)
```

## 前端加载方式

layout 里没有任何 htmx 的 `<script>` 标签,只有 `javascript_importmap_tags`:

```erb
<%= stylesheet_link_tag :app %>
<%= javascript_importmap_tags %>
```

htmx 由 `app/javascript/application.js` 自己 import 进来:

```js
import htmx from "htmx"   // importmap 把裸标识符解析成 /assets/htmx.esm-<digest>.js
window.htmx = htmx        // 让 hx-on 表达式、扩展和浏览器控制台都能拿到 htmx
```

好处是**没有加载顺序问题**:模块的依赖图保证 htmx 先于 `htmx.config` 那几行执行
(之前用 `<script defer>` 依赖"经典 defer 脚本先于模块脚本执行"的约定)。
`window.htmx = htmx` 是必要的:模块作用域里的 `htmx` 不是全局的,而 `hx-on`
表达式是在全局里求值的。

代价:htmx 的 ESM 构建(`dist/htmx.esm.js`,168 KB)只有**未压缩**版本,
而经典构建的 `htmx.min.js` 是 51 KB(gzip 后差距小得多)。做演示时未压缩反而
便于在 DevTools 里读源码、下断点;真要上线,换 `htmx.min.js` 或走打包器即可。

## 两个环境说明

* **Hotwire 已移除。** `turbo-rails` 和 `stimulus-rails` 都从 Gemfile 删掉了:
  importmap 里的 pin、`data-turbo-track`、以及 `app/javascript/controllers/`
  (Stimulus 的 `application.js` / `index.js` / `hello_controller.js`,Rails 默认
  模板,演示里从未用到)一并清掉。现在 `app/javascript/application.js` 是全应用
  唯一的 JS 文件,只做三件事:import htmx、配置 422 也交换、监听 `HX-Trigger`
  弹 toast。
  删 Hotwire 是安全的:`ApplicationController` 里的
  `stale_when_importmap_changes` 来自 `importmap-rails`
  (`app/controllers/importmap/freshness.rb`),与 Turbo 无关。
  唯一残留的是 `javascript_importmap_tags` 写死在 importmap `<script>` 上的
  `data-turbo-track="reload"`(importmap-rails 自己的模板,没有配置项),
  没有 Turbo 时无人读取,可以忽略。
  保留 `importmap-rails` 本身:它不属于 Hotwire,是 Rails 8 默认的 JS 交付方式,
  也是上面那行 `stale_when_importmap_changes` 的来源。
* **`json` 固定在 2.x。** ActiveSupport 8.1 仍以位置参数调用
  `JSON.parse(source, options)`,而 json 3.x 不再接受第二个位置参数。不加这个
  约束,任何携带加密 session cookie 的请求(也就是浏览器里每一次表单提交)
  都会在解密 cookie 时 500。`test/controllers/pages_controller_test.rb` 里有一个
  打开 CSRF 保护的测试专门守住这条路径。
