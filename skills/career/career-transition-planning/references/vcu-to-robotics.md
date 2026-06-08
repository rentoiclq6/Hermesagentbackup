# Case Study: VCU → Robotics Transition (Full Session Record)

## Source Session

Produced for user 李辉 (24, 211 Vehicle Engineering, 3yr VCU at JAC).
- Resume: `F:\找工作\document 中文初版.md` → `/mnt/f/找工作/document 中文初版.md`
- Output file: `C:\Users\da\Documents\My Cheat Tables\公司名单.md`
- Visual output: `C:\Users\da\Desktop\技能图谱_VCU转机器人.html`

## Skill Transfer Mapping

| VCU Skill | Robotics Equivalent | Gap Level |
|-----------|-------------------|-----------|
| MATLAB/Simulink MBD | Robot kinematics modeling, control simulation | Direct transfer |
| C/C++ embedded (3yr mass prod) | Robot real-time control, MCU firmware | **Direct — strongest asset** |
| CAN/LIN/Ethernet, DBC/LDF | CANopen, EtherCAT, ROS2 middleware | Minor gap (need ROS2 comms pattern) |
| Kalman filter (LMS/RLS, 90% acc) | Robot state estimation, IMU/VIO fusion | Direct transfer |
| ISO 26262 (in production) | IEC 61508, ISO 13482 | Minor gap (standard details differ) |
| V-Model / MiL / HiL | Robot HITL / SITL testing | Direct transfer |
| Simulink auto code gen | Embedded Coder for robot targets | Direct transfer |
| CANape / CANoe / INCA | Robot debugging tools (concept similar) | Direct transfer |
| 4 mass-production projects | Systems engineering, closed-loop quality | **Key differentiator vs pure-algo candidates** |

## Company Tiers (Robotics Target)

### Tier 1 — Strongly Recommended
| Company | City | Direction | Est. Salary | Rationale |
|---------|------|-----------|-------------|-----------|
| 智元机器人 (Agibot) | Shanghai | Humanoid | 25-45k·15 | Peng Zhihui's venture; control stack is core |
| 宇树科技 (Unitree) | Hangzhou/Shanghai | Quadruped/Humanoid | 25-40k·14 | Global leader in quadrupeds; needs C++ + real-time |
| 大疆 (DJI) | Shenzhen/Shanghai | Drone/Automotive | 30-55k·15 | Embedded control is DNA; CAN/filtering fits |
| 小鹏机器人 | Guangzhou/Shanghai | Humanoid | 25-45k·14 | Closest to automotive pipeline; natural transition |

### Tier 2 — Good Fit
| Company | City | Est. Salary | Notes |
|---------|------|-------------|-------|
| 傅利叶智能 (Fourier) | Shanghai | 20-40k·14 | Exoskeleton → GR-2 humanoid; Simulink direct fit |
| 星动纪元 (Star Dynamics) | Beijing | 25-45k·15 | Tsinghua lineage; full-body motion control |
| 地平线 (Horizon Robotics) | Beijing/Shanghai | 30-50k·15 | ADAS → robot platform; closest tech stack |
| 海康机器人 (Hikrobot) | Hangzhou | 20-35k·14 | AMR market leader; stable, many embedded roles |

### Tier 3 — Fallback / Experience
追觅、优必选、节卡、埃斯顿、极智嘉 — 18-35k range

## Safety Net (Current Industry — 30% effort)

### Preferred (top match)
1. **博世 (Bosch)** — 20-35k, best springboard for eventual robotics pivot
2. **大陆 (Continental)** — 18-30k, VCU-dense
3. **安波福 (Aptiv)** — 15-25k, job title is literally "整车控制工程师"
4. **里卡多 (Ricardo)** — 20-35k, VCU/HCU embedded contractor
5. **Stellantis** — 20-25k, transparent salary, direct VCU match

### Fallback (lower match)
大众、沃尔沃、采埃孚、奔驰、宝马、法雷奥、捷豹路虎、雷诺

## Visual Output Reference

The HTML visualization (`技能图谱_VCU转机器人.html`) contained:
- **Venn diagram**: Left=existing skills, Right=robot needs, Center=8 overlapping skills
- **23-row detailed comparison table**: 5 categories (Embedded, Control, Comms, Tools, Safety)
- **Radar gauge chart**: 9 key skills rated 1-5 vs robot requirement
- **P0-P3 learning path**: ROS2(2wk) → Gazebo(1wk) → Kinematics(2wk) → EtherCAT(2wk) → Python/CANopen(1wk) → MPC/IMU(1wk) → Safety(3d) → SLAM(1wk)
- **Resume keyword rewrite**: 10 original→target pairs

## Resume Keyword Translation Table

| Original (VCU) | Target (Robotics) |
|----------------|-------------------|
| 整车控制工程师 | 嵌入式控制系统工程师 |
| VCU控制器 | 车辆/机器人控制器 (ECU/MCU) |
| 整车控制策略 | 运动控制系统 |
| 换挡策略 | 行为控制 / 状态机 |
| CAN/LIN通讯矩阵 | 车载/机器人总线通信 |
| 车重/坡度估算 (卡尔曼滤波) | 状态估计 (卡尔曼滤波 / MHE) |
| HiL/MiL测试 | HITL / SITL 硬件在环测试 |
| 实车标定 | 实物调试与参数整定 |
| ISO 26262 功能安全 | 功能安全 (ISO 26262 / IEC 61508) |
| 动力系统控制 | 电机控制 / 伺服控制 |

## Key Lessons from This Session

1. **User corrected file discovery** — mount point check needs to be the FIRST action, not incremental
2. **HTML visualization** — received no negative feedback, user engaged with the output. Worth including as standard step for complex transitions
3. **Dual-track strategy** — user didn't push back on keeping automotive as safety net, confirming this structure is useful
4. **Salary transparency** — user didn't question estimates, suggesting they value the honesty
5. **The Venn diagram + radar combo** was the highest-value part of the visual output based on engagement
