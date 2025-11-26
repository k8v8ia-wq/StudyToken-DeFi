# CDS528 Group Project Code - EduMerit Platform

> **StudyToken (STU) & AchievementReward 前后端整合项目**
> 本项目实现了一个基于区块链的去中心化激励平台，包含完整的智能合约、ABI 接口、前端交互页面及部署脚本。

## 项目概览 (Overview)
该平台旨在通过双重激励机制（铸造模式 vs 金库模式）来奖励学生的学术成就。项目整合了 `StudyToken` (ERC20) 与 `AchievementReward` (逻辑控制) 两个核心合约，并提供了配套的管理端与用户端前端界面。

---

## 👥 小组成员 (Group Members)
| 姓名 (Name) | 学号 (ID) | 角色 (Role) |
| :--- | :--- | :--- |
| **ZHENG GuangYuan** | (5541645) | Testing & Security &DevOps |
| **WU Ke** | (填写学号) | Frontend & Integration |
| **Gan Haohong** | (填写学号) | Backend & UI/UX Design|
| **ZHUANG Jingkun** | (填写学号) | Documentation |
| **LIAO Ziang** | (填写学号) | Testing & Security |

---

##  Video (演示视频)
**[点击这里观看项目演示视频 (Click to Watch)](在此处粘贴你的Youtube或Drive视频链接)**

---

## 目录结构 (Directory Structure)

本项目根目录为 `CDS528_group_project_code`，核心文件结构如下：

- **`contracts/`** (智能合约源文件)
  - `StudyToken_pure.sol`：STU 代币合约（包含 Mint/Pause 功能）。
  - `achivementreward.sol`：成就奖励逻辑合约（处理审核、发奖）。

- **`abis/`** (前端交互接口)
  - `StudyToken_pure.json`：StudyToken 的 ABI 文件。
  - `AchievementReward.json`：AchievementReward 的 ABI 文件。

- **`frontend/`** (Web3 前端页面)
  - `achievement_reward_front.html`：**用户端**，用于学生提交成就证明与查询状态。
  - `achievement_reward_admin.html`：**管理端**，管理员在此设置参数（MintLimit）、审核申请、暂停系统。
  - `study_token_demo.html`：**代币演示页**，用于管理员手动铸币或转移权限。

- **`scripts/`** (Hardhat 部署脚本)
  - `deploy_studytoken.js`：部署 Token 合约。
  - `deploy_achievementreward.js`：部署奖励合约并关联 Token。

---

## 快速启动与安装 (Setup & Installation)

### 1. 环境准备
确保本地已安装 Node.js 和 Git。

```bash
git clone [https://github.com/k8v8ia-wq/StudyToken-DeFi.git](https://github.com/k8v8ia-wq/StudyToken-DeFi.git)

cd CDS528_group_project_code

npm install
