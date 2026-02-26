---
name: fix-status-and-delivery-image
overview: 修复管理端订单状态显示与枚举不一致，以及商户订单完成后派送图片在详情中无法显示的问题。
todos:
  - id: scan-status-fields
    content: 使用 [subagent:code-explorer] 复查订单状态与配送图片字段引用范围
    status: completed
  - id: fix-admin-status
    content: 修正管理员订单列表状态筛选、计数与文本映射（PrintEase-uniapp/src/pages/admin/order-list.vue）
    status: completed
    dependencies:
      - scan-status-fields
  - id: fix-detail-types
    content: 补充 deliveryImageUrl 类型并对齐详情页展示逻辑（PrintEase-uniapp/src/types/index.ts、PrintEase-uniapp/src/pages/order/detail.vue）
    status: completed
    dependencies:
      - scan-status-fields
  - id: fix-cancel-state
    content: 调整取消订单本地状态值为 CANCELLED（PrintEase-uniapp/src/store/order.ts）
    status: completed
    dependencies:
      - fix-admin-status
  - id: backend-return-image
    content: 在订单详情与刷新接口返回 deliveryImageUrl（PrintEase-backend/src/modules/order/order.controller.ts）
    status: completed
    dependencies:
      - scan-status-fields
---

## User Requirements

- 修正管理员面板订单状态编号与文案不一致的问题，使状态 4 显示为“已完成”而非“已取消”
- 修复商户面板订单完成时配送图片无法在详情中展示的问题
- 状态筛选与数量统计需与正确状态编号一致，避免前端显示与实际状态错配

## Product Overview

- 订单管理与订单详情页面正确展示订单状态与配送图片，确保状态含义一致、信息完整可见

## Core Features

- 管理员订单列表状态筛选、状态文本与徽标计数按正确状态编号显示
- 订单详情在完成状态下展示配送图片，点击可预览
- 订单详情/刷新状态返回值包含配送图片字段，前端类型可接收

## Tech Stack Selection

- 前端：uni-app（Vue 3 + TypeScript + Pinia）
- 后端：NestJS（TypeScript）

## Implementation Approach

- 以现有状态枚举为单一真源，统一管理员列表中的状态筛选、状态文本与样式映射；对前端本地状态更新同步调整取消状态值，避免显示错配
- 在订单详情接口与刷新接口中补充配送图片字段，前端类型与详情页绑定字段保持一致，确保刷新后图片不丢失
- 变更范围限制在订单展示与详情数据字段补齐，避免引入新模式或大范围重构

## Implementation Notes (Execution Details)

- 复用现有 OrderStatus 枚举值或常量映射，避免硬编码重复导致的错配
- 订单列表过滤与统计仍为 O(n) 遍历，保持当前性能；不新增网络请求
- 接口仅新增可选字段 deliveryImageUrl，保持向后兼容；不改动鉴权逻辑

## Architecture Design

- 维持现有前端页面 + API + store 架构：订单详情依赖 store → API → 后端 controller → service → entity
- 仅在 controller 响应字段层补充 deliveryImageUrl，不改动 service 查询路径

## Directory Structure Summary

本次修改集中在订单状态映射与订单详情字段补齐，涉及前端页面、类型定义、store 及后端控制器返回结构。

- PrintEase-uniapp/src/pages/admin/order-list.vue  # [MODIFY] 调整状态筛选/统计与状态文本、样式映射，使状态4为“已完成”，状态5为“已取消”
- PrintEase-uniapp/src/pages/order/detail.vue       # [MODIFY] 保持完成状态展示配送图片逻辑，更新与枚举一致的状态判断（若引用枚举）
- PrintEase-uniapp/src/store/order.ts               # [MODIFY] 取消订单本地状态更新为 CANCELLED 编号，避免显示为完成
- PrintEase-uniapp/src/types/index.ts               # [MODIFY] OrderInfo 增加 deliveryImageUrl 字段定义
- PrintEase-backend/src/modules/order/order.controller.ts  # [MODIFY] 订单详情与刷新接口返回 deliveryImageUrl 字段

## Agent Extensions

- **SubAgent: code-explorer**
- Purpose: 全量复查订单状态枚举与配送图片字段在前后端的引用范围
- Expected outcome: 明确所有需同步修改的状态映射与字段返回位置，避免遗漏