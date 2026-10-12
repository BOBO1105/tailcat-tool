# Tailcat Manager for macOS

SwiftUI 设备侧栏应用，管理多个独立 Tailcat → ADB 会话。第一版面向本机使用，macOS 13 及以上；当前构建目标为 Apple Silicon。

## 构建和启动

需要 macOS Command Line Tools（Swift 5.9+）或 Xcode，以及支持 `forward`、`parse` 的 Tailcat。已验证本机 Tailcat v0.7.0。

```sh
bash scripts/build-app.sh
open "dist/Tailcat Manager.app"
```

脚本同时生成 `dist/Tailcat-Manager-<版本>.zip`，其中只包含已签名的应用包。

也可以开发运行：

```sh
swift run TailcatManager
```

应用从 Homebrew、`~/.local/bin`、Android SDK 和 PATH 检测工具。“工具设置”可指定 Tailcat、ADB、scrcpy 可执行文件和地址簿目录。ADB 必需；scrcpy 仅用于屏幕控制。

缺失组件可以点侧栏或工具设置中的“安装”，也可点“安装缺失组件”依次安装全部缺失工具。使用 Homebrew 官方命令：[Tailcat](https://formulae.brew.sh/formula/tailcat) 为 `brew install tailcat`，[ADB](https://formulae.brew.sh/cask/android-platform-tools) 为 `brew install --cask android-platform-tools`，[scrcpy](https://formulae.brew.sh/formula/scrcpy) 为 `brew install scrcpy`。界面显示进度和日志，支持取消及失败后重试，成功后自动保存路径。已存在的工具直接检测并配置。

安装只在用户点击时运行；该次命令关闭 Homebrew 自动更新、已安装包升级、安装后清理和依赖包检查，避免额外变动。安装缺失工具所必需的依赖仍交由 Homebrew 处理。未检测到 Homebrew 时提供官方安装页面入口，需要先完成 Homebrew 安装。

本地 `.app` 使用 ad-hoc 签名，不是经过 Developer ID 签名和公证的分发包。没有打包现有地址、私钥或命令二进制。

## 使用

- 首次启动时，如果应用还没有设备，会导入现有 `tailcat-adb/users/` 地址簿。之后可点工具栏“导入地址簿”，只添加缺失用户，保留 GUI 内的编辑。
- 工具栏闪电按钮、侧栏“新建临时连接”或 `⌘⇧N` 可建立临时设备。只需填写连接地址，名称可选；本地端口默认自动分配。临时设备单独分组，支持多台同时连接以及全部常用 ADB 操作。
- 临时配置和凭据仅保存在内存中，不写配置文件、Keychain 或 CLI 地址簿。断开后在本次运行中仍可重连；关闭临时设备或退出应用时停止其通道并清除临时配置。需要保留时点“保存到我的设备”，当前 UUID、通道和正在执行的任务保持，凭据从此保存到 Keychain。
- 默认地址簿位于 `${XDG_STATE_HOME:-~/.local/state}/tailcat-adb`。Finder 启动不一定继承终端的 XDG 环境变量，自定义位置请在设置中指定。
- 地址簿是只读来源；不改写 `address`、`current-user`、`local-port`、PID 或日志，也不接管现有 CLI 通道。
- 启动和运行期间约每 3 秒识别已有 CLI 通道，在对应设备下显示“CLI 外部连接”、本地入口、PID、设备型号和 ADB 状态。支持同一设备多个 CLI 端口，并可与该设备的 GUI 通道分别显示。
- 识别会核对 `bridges/<port>.pid`（兼容旧 `bridge.pid`）、实际 socat 命令、监听 PID/端口、连接地址与 GUI 当前凭据；跳过符号链接、失效 PID、端口不一致及其他进程。识别不会连接、重连、断开或结束 CLI 进程。
- 已在线的 CLI 外部连接可以使用终端、安装 APK、文件传输、Shell、链路探测和 scrcpy；会自动读取设备信息，也可点“刷新信息”。执行设备操作前再次核对 CLI 的进程、监听和 ADB 状态；入口被替换或设备未授权时拒绝操作。CLI 的重连、断开仍由 CLI 控制。
- 添加设备后选择“连接”。每台设备有独立进程和 ADB serial，支持同时连接。自动端口从 5556 到 5655 逐个实际绑定，已有监听端口保持；也可为设备指定固定端口。
- 待授权、离线、转发进程退出分别显示。只有 ADB `device` 状态允许安装、文件传输、Shell 和 scrcpy。
- 所有任务在启动时固定设备、ADB 路径及 serial。切换侧栏不会改变任务目标；重连、断开会先取消该设备正在执行的任务。
- 支持 APK 覆盖安装、文件/目录上传下载、单条 Shell 命令、系统 Terminal 和独立 scrcpy 窗口。任务输出与取消按钮位于底部。
- 关闭主窗口后连接继续运行，从菜单栏重新打开；退出应用会停止 GUI 启动的设备任务（包括 CLI 入口上的 GUI 任务）及应用创建的通道，只对应用自建通道的 serial 执行 `adb disconnect`，保留 CLI 通道，不会重启全局 ADB 服务。
- ADB 离线时最多尝试 6 次恢复，间隔逐步增加；待授权不自动重试。唤醒后重新检测。转发进程退出时由用户点击“重新连接”。

取消会停止本机命令进程，远端已经发生的安装或文件写入不会自动回滚。传输任务、Shell 命令、连接状态都有超时；持续使用的 scrcpy 会话最多运行 24 小时。

## 配置与凭据

设备连接地址存入本机 Keychain，读取或更新时可能出现 macOS 的 Keychain 授权提示。名称、端口和工具路径保存在：

```text
~/Library/Application Support/TailcatManager/configuration.json
```

目录权限为 700，配置文件为 600；配置文件不包含连接凭据。日志自动隐藏完整 `tc...` 地址。Tailcat 客户端身份仍按 Tailcat 自身的现有默认配置读取；不会生成、导出或替换用户私钥。

源码仓库只包含代码、测试、构建脚本和图标资源。本机配置、连接地址簿、Keychain 内容、私钥及证书导出、日志和 `.build` / `dist` 构建输出不上传；`.gitignore` 已排除相应文件与目录。测试中的完整 Tailcat 地址来自官方公开文档示例，其余地址为测试时生成的模拟值。

## 验证

```sh
swift run TailcatChecks
swift run TailcatChecks --native-tailcat
swift run TailcatChecks --native-tailcat --keychain
```

验证程序不依赖 XCTest / Swift Testing，适用于只有 Command Line Tools 的机器。覆盖双设备隔离、固定任务目标、待授权、连接取消、重连取消旧任务、异常退出、地址簿只读导入、配置权限、参数传递、双管道输出、进程超时和取消；另外覆盖临时设备不落盘、不访问持久凭据、独立关闭、保存时保留正在执行的任务、保存失败回滚，CLI 多端口识别、入口更换拒绝操作、元数据和 ADB/scrcpy 操作、退出取消 GUI 任务但保留 CLI 通道，以及 Homebrew 命令、批量安装、自动配置、失败和取消。安装行为使用模拟 Homebrew，不改动本机已安装组件。

`--native-tailcat` 额外使用已安装 Tailcat 创建两个本地监听端口，验证就绪输出、端口避让和独立退出；使用官方公开示例地址，不拨号到远端，不连接真实车机。该验证不等于实车端到端验收。

`--keychain` 使用随机 UUID 的模拟凭据验证 Keychain 的创建、读取、更新和删除，结束后删除测试条目，不读取真实设备凭据。

界面演示：

```sh
open "dist/Tailcat Manager.app" --args --demo
```

演示模式使用内存配置和模拟命令，不读取真实地址簿、不写 Keychain，也不执行真实设备操作。退出已启动的普通实例后，再启动演示模式。

## 目录

- `Sources/TailcatCore`：配置、地址簿、Keychain、进程与独立会话、任务和 ADB 状态管理。
- `Sources/TailcatManager`：SwiftUI 侧栏、设备详情、表单、菜单栏和演示环境。
- `Tests/TailcatCoreTests`：可独立运行的行为验证程序。
- `scripts/build-app.sh`：Release 构建与本地 `.app` 打包。
- `resources/AppIcon.png`：图标原图；`scripts/build-icon.sh` 生成包含标准与 Retina 尺寸的 `AppIcon.icns`，随应用包一起签名。

第一版不包含远端 Tailcat 部署、客户端密钥管理、内嵌视频/终端、云同步或应用内自动更新。

正常退出会清理连接。强制结束应用或应用崩溃后的孤儿进程恢复尚未实现；旧监听会被新实例避让，第一版不会按 PID 文件自动结束不明进程。
