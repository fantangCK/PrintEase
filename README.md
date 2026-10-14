# PrintEase 印易

PrintEase 是由小程序、管理后台、业务后端、文件转换服务、Windows 打印客户端和支付服务组成的打印业务工程。各应用以 Git 子模块维护；本仓库提供工程索引和联合部署入口。

## 工程组成

| 目录 | 职责 | 维护文档 |
| --- | --- | --- |
| `PrintEase-backend/` | NestJS 后端：认证、用户、文件、订单、支付对接、配送、打印调度和系统配置 | [后端 README](./PrintEase-backend/README.md) |
| `PrintEase-admin/` | Vue 管理后台：订单、用户、商户及系统运营配置 | [项目配置](./PrintEase-admin/package.json) |
| `PrintEase-uniapp/` | uni-app 小程序：上传、下单、支付、订单查询及商户业务 | [小程序 README](./PrintEase-uniapp/README.MD) |
| `PrintEase-dispatch/` | Python 桌面打印客户端：任务认领、文件下载、Windows 打印和状态上报 | [客户端 README](./PrintEase-dispatch/README.md) |
| `convert2api/` | 独立转换 API、持久化任务队列、Windows WPS Worker 和转换 EXE | [转换服务 README](./convert2api/README.md) |
| `mpay/` | PHP 码支付应用及 Docker 部署配置 | [支付服务 README](./mpay/README.md) |
| `docs/` | 业务和架构资料，历史方案位于 `archived_docs/` | [业务架构](./docs/后端-开发计划与架构.md) |

数据库部署资产位于 `PrintEase-backend/docker/database/`，生产后端和代理配置位于 `PrintEase-backend/docker/production/`。工程根入口是 [start-printease-docker.ps1](./start-printease-docker.ps1)，没有独立的根 `docker/` 目录。

## 业务与运行边界

小程序和管理后台通过后端 API 操作业务数据。后端处理上传、订单、支付回调、配送和打印任务，并可提交远程转换任务。转换 API 管理任务与产物，Windows Worker 在专用 WPS 会话中执行 Office 转 PDF。打印客户端独立领取打印任务并调用 Windows 打印工具。

转换 EXE 每次处理一个文件：`office2pdf.exe` 转 PDF 并分析页数和覆盖率；`converter.exe` 转 PDF、读取页数，返回固定覆盖率。API 和 Worker 不包含在这两个 EXE 中。现有二进制是否对应最新源码、Office COM 和真实打印行为均需要单独验收，不能以源码测试或构建成功代替。

当前打印链路依赖 Windows 驱动与 SumatraPDF，不承诺 Linux/macOS 实际打印支持。客户端心跳兼容接口也不等同于完整节点在线监控。支付功能取决于具体渠道与监听配置；mpay 的 `/payHeart` 路由与私有方法存在适配限制，定时请求成功启动不能证明收款监听可用，详见支付 README。

## 获取工程和环境

```powershell
git clone --recurse-submodules <本工程仓库地址>
# 对已克隆但尚未初始化的工作区执行：
git submodule update --init --recursive
```

运行前准备各应用的私有配置，不覆盖已有 `.env`。环境要求按子项目分别确认：

- 后端建议 Node.js 22.19.0，与 CI 和部署脚本一致；数据库使用 MySQL 8.0。
- 管理后台要求 Node.js >=20.19.0、npm >=10；采用 Node.js 22.19.0 可与后端统一。
- 打印客户端和转换项目共用 Conda `printease-dev`、Python 3.11；两工程的运行、开发、构建依赖清单与带哈希锁文件一致。任一工程创建环境即可，已存在时使用 `conda env update -f environment.yml`。
- WPS Worker 需要 Windows、已安装并可自动化调用的 WPS，以及专用交互会话。
- mpay 使用 PHP >=8.0，容器采用 PHP 8.2；Windows 部署脚本使用 PowerShell 7，容器部署需要 Docker Compose。

## 本地开发入口

以下命令从各自子项目目录执行。数据库、证书、API 地址及密钥须先按对应 README 配好。

### 后端

```powershell
npm ci
# 仅首次配置且没有 .env 时复制：
Copy-Item .env.example .env
npm run start:dev
```

新空库需先按后端 README 配置初始化账号，执行 `npm run db:init`，再执行 `npm run db:seed:system -- --apply`。已有数据库使用经过审查的迁移流程；不要重新初始化已有业务库。构建命令为 `npm run build`，生产运行入口为 `npm run start:prod`。

### 管理后台和小程序

```powershell
# 在 PrintEase-admin：
npm ci
npm run dev
npm run build

# 在 PrintEase-uniapp：
npm ci
npm run dev:mp-weixin
npm run build:mp-weixin
```

小程序产物需使用微信开发者工具加载并配置合法域名、AppID 与 HTTPS。管理后台 API 配置遵循该项目环境文件。客户端 API 契约来自后端生成产物，相关生成和校验命令见各项目 README 与 package.json。

### 打印客户端

```powershell
conda env create -f environment.yml
conda activate printease-dev
python -m pip check
python -m src.main
```

打印机、后端地址、认证及 SumatraPDF 配置见客户端 README。打包入口为 `scripts/build.ps1`，需要真实 SHA 和 RunId；打包完成后仍需目标机器打印验收。

### 转换服务

```powershell
# 共用环境已创建时不再重复创建：
conda activate printease-dev
python -m pip check
# 安装本地源码和 CLI 入口（依赖已由共享锁文件安装）：
python -m pip install -e .
# 配置 CONVERTER_* 环境变量后启动 API：
python -m convert2api api --host 127.0.0.1 --port 8080
# Windows Worker 使用独立私有配置：
./scripts/start.ps1 -ConfigFile C:/PrintEase/private/worker.json -Python python
```

EXE 构建使用 `scripts/build.ps1` 和 `requirements-build.txt`。标准 `dist/office2pdf.exe` 路径需要构建产物；另存的重建产物需要显式配置与验收。完整参数、数据库 schema、TLS、任务协议及限制见转换 README。

### 支付应用

在 `mpay/www/` 安装 PHP 依赖并配置 MySQL 后，可用 `php think run` 进行本地调试。容器部署涉及私有配置、数据库账号、TLS 和外部网络，应遵循 [mpay 部署说明](./mpay/README.md)，不要把无参数 `docker compose up -d` 当成完整初始化流程。

## 后端数据与证书目录

```text
PrintEase-backend/
├── data/
│   ├── uploads/
│   │   ├── avatar/
│   │   ├── original/
│   │   ├── converted/
│   │   ├── delivery/
│   │   ├── notice/
│   │   └── temp/
│   ├── redis-data/
│   └── logs/
└── ssl/
    ├── <API 证书>.pem
    └── <API 私钥>.key
```

默认 `UPLOAD_DIR=./data/uploads`、`LOG_DIR=./data/logs`；分片临时文件跟随上传根目录。头像物理路径为上传根目录下的 `avatar/`，已有 `/avatar` 和 `/uploads` URL 保持兼容。API 证书直接放在 `ssl/` 根目录，不再使用 `ssl/api/`。

Redis 持久化挂载到 `data/redis-data`，开关由 `REDIS_ENABLED` 控制；客户端仍通过网络连接 Redis。MySQL 数据使用 Docker 命名卷，不属于这次本地 `data/` 整理。运行数据、私有证书与环境文件不进入发布包，不应提交到仓库。

## 联合部署

在工程根目录执行，并提供已准备好的私有环境文件：

```powershell
./start-printease-docker.ps1 -EnvFile C:/PrintEase/private/deployment.env -Plan -Components database,converter,mpay,backend,proxy
./start-printease-docker.ps1 -EnvFile C:/PrintEase/private/deployment.env -ValidateOnly -Components database,converter,mpay,backend,proxy
```

`-Plan` 只输出部署顺序，不进行配置验证；`-ValidateOnly` 验证所选配置，不启动服务。真实部署需准备私有文件、证书、外部网络及数据库 schema 后再移除这些开关。WPS Worker 保持 Windows 原生运行。

数据库启动、账号及卷管理见 [数据库 README](./PrintEase-backend/docker/database/README.md)。测试部署采用后端 `scripts/deploy/` 中的构建产物与共享 `data` 链接，部署前检查目录、环境配置和产物身份；已有主机数据迁移应另行完成。

## 文档维护与许可

维护入口为本文件及各子项目 README。`docs/archived_docs/`、转换项目 `migration/`、`mpay/www/README_old.md` 属于历史材料，依赖包、缓存及构建目录中的 README 不作为当前工程操作指南。

本工程包含独立子仓库及第三方组件，许可应以各组件的实际许可文件和 package 元数据为准。后端 package 标识为 `UNLICENSED`；本索引不授予整个工程统一的 MIT 许可。
