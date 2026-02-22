# PrintEase 印易

轻松打印，就选印易！

## 项目简介

PrintEase 印易是一个完整的自助打印解决方案，集成了文件上传、格式转换、在线支付、订单管理和云印调度等功能，为用户提供便捷的打印服务体验。


## 项目结构

```
PrintEase/
├── PrintEase-admin/          # 管理后台 (待开发)
├── PrintEase-backend/        # 后端服务
│   ├── converter/            # 文件转换服务
│   ├── src/
│   │   └── modules/
│   │       ├── auth/         # 认证模块
│   │       ├── user/         # 用户模块
│   │       ├── file/         # 文件模块
│   │       ├── order/        # 订单模块
│   │       ├── dispatch/     # 调度模块
│   │       ├── system/       # 系统模块
│   │       └── conversion/   # 转换模块
│   └── ...
├── PrintEase-dispatch/       # 云印调度客户端
├── PrintEase-uniapp/         # 微信小程序
├── mpay/                     # 码支付系统
├── docker/                   # Docker 配置
├── docs/                     # 项目文档
└── README.md
```

## 核心功能

### 1. 用户端 (小程序)
- 微信快捷登录
- 文件上传与管理
- 打印参数配置（黑白/彩色、单面/双面、份数等）
- 在线支付（微信支付、支付宝）
- 订单追踪与管理
- 个人中心

### 2. 管理后台
- 订单管理与统计
- 用户管理
- 商户管理
- 价格配置
- 云印节点监控
- 打印任务调度

### 3. 商户端
- 商户登录
- 抢单大厅
- 订单管理
- 打印任务执行
- 收益统计

### 4. 云印调度
- 多节点分布式打印
- 自动任务轮询与认领
- 跨平台打印支持（Windows/Linux/macOS）
- 实时状态上报
- 心跳保活机制

## 快速开始

### 环境要求
- Node.js 18+
- Python 3.10+
- MySQL 8.0+
- Docker (可选)

### 1. 后端服务
```bash
cd PrintEase-backend
npm install
cp .env.example .env
# 配置数据库等环境变量
npm run start:dev
```

### 2. 微信小程序
```bash
cd PrintEase-uniapp
npm install
npm run dev:mp-weixin
```

### 3. 云印调度
```bash
cd PrintEase-dispatch
conda env create -f environment.yml
conda activate printease-dispatch
python src/main.py
```

### 4. 码支付
```bash
cd mpay
docker compose up -d
```

详细文档请参考各子模块的 README。

## 相关文档

- [后端 API 与数据库](./docs/后端-API与数据库.md)
- [后端开发计划与架构](./docs/后端-开发计划与架构.md)
- [后端文件处理服务](./docs/后端-文件处理服务.md)
- [小程序前端逻辑](./docs/小程序-前端逻辑.md)
- [小程序开发指南](./docs/小程序-开发指南.md)
- [支付集成指南](./docs/支付-集成指南.md)
- [调度业务流程](./docs/调度-业务流程.md)
- [项目环境与工具](./docs/项目-环境与工具.md)

## 相关项目

- [PrintEase-backend](./PrintEase-backend) - 印易后端服务
- [PrintEase-uniapp](./PrintEase-uniapp) - 印易微信小程序
- [PrintEase-dispatch](./PrintEase-dispatch) - 印易云印调度
- [PrintEase-admin](./PrintEase-admin) - 印易管理后台
- [mpay](./mpay) - 印易支付系统

## License

MIT
