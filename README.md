# CDS528 - StudyToken 与 AchievementReward 前后端整合

该目录整合了 StudyToken 与 AchievementReward 的合约、ABI、前端页面与部署脚本，便于统一使用与维护。

## 目录结构
- `contracts/`
  - `StudyToken_pure.sol`：STU 代币合约。
  - `achivementreward.sol`：成就奖励合约。
- `abis/`
  - `StudyToken_pure.json`：StudyToken ABI。
  - `AchievementReward.json`：AchievementReward ABI。
- `frontend/`
  - `achievement_reward_front.html`：用户提交与查询页面。
  - `achievement_reward_admin.html`：管理后台页面（设置 StudyToken、useMint、mintLimit、评审与暂停）。
  - `study_token_demo.html`：StudyToken 演示页（管理员操作如铸币与更换管理员）。
- `scripts/`
  - `deploy_studytoken.js`：StudyToken 部署脚本。
  - `deploy_achievementreward.js`：AchievementReward 部署脚本。

## 启动与访问
进入 `CDS528` 目录并启动本地静态服务器：

```
cd CDS528
py -m http.server 8000
```

打开页面：
- 用户页：`http://localhost:8000/frontend/achievement_reward_front.html`
- 管理页：`http://localhost:8000/frontend/achievement_reward_admin.html`
- 代币页：`http://localhost:8000/frontend/study_token_demo.html`

## 使用流程简述
1. 如需铸造模式（useMint=true）：
   - 在 StudyToken 上将 AchievementReward 设为管理员（StudyToken 更换管理员）。
   - 在 AchievementReward 上切换 `useMint=true`，并设置合适的 `mintLimit`（单位 STU，前端会转换为 18 位精度）。
2. 如需金库模式（useMint=false）：
   - 给 AchievementReward 合约地址转入足够的 STU（作为金库余额），审核通过后直接转账发奖。
3. 用户提交与查询在用户页进行；审核与参数管理在管理页进行。

## 注意事项
- 钱包网络需与合约部署网络一致（如本地/测试网）。
- ABI 由前端从 `abis` 目录加载；若更新合约请重新生成 ABI。
- 管理员权限严格控制；更换管理员需要当前管理员账户进行。
- `mintLimit` 输入使用 STU 直觉单位，内部转换为 Wei（18 位）。

## 其他
- 项目配置文件（`hardhat.config.js`、`package.json`）已迁移到 `CDS528` 目录，建议在该目录下执行 Hardhat 与 npm 命令。
- 如需进一步精简，可继续迁移或归档文档文件；若删除受限，可改为移动到 `CDS528` 下进行归档。