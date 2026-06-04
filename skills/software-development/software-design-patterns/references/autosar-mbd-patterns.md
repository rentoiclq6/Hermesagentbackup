# AUTOSAR MBD + Design Patterns

Maps all 23 GoF design patterns to AUTOSAR (Classic + Adaptive) and Simulink/Model-Based Design workflows. Written from the perspective of an automotive embedded developer doing MBD with AUTOSAR toolchains.

---

## Relevance Heatmap (AUTOSAR context)

| Priority | Pattern | Why it matters in AUTOSAR |
|----------|---------|--------------------------|
| 🔴🔴🔴 | **State** | Stateflow is the backbone of SWC behavior modeling. Every Runnable manages state transitions. |
| 🔴🔴🔴 | **Observer** | Sender-Receiver (S/R) communication — the fundamental data exchange pattern in AUTOSAR. |
| 🔴🔴🔴 | **Mediator** | RTE *is* a Mediator. SWCs never communicate directly; RTE routes all data and calls. |
| 🔴🔴 | **Chain of Responsibility** | COM Stack (Com → PduR → CanIf → CanDrv) and Diagnostic Stack (Dcm → Dem → FiM) are textbook CoR. |
| 🔴🔴 | **Strategy** | Multiple calibration sets / drive modes switching algorithms at runtime. |
| 🔴🔴 | **Composite** | Composition SWC nests Atomic SWCs. Simulink model hierarchy mirrors this. |
| 🔴🔴 | **Proxy** | Cross-ECU VFB communication generates Proxy SWCs. Adaptive AUTOSAR ara::com is built on Proxy/Skeleton. |
| 🔴 | **Adapter** | ECU Abstraction Layer adapting MCAL to standardized BSW API. |
| 🔴 | **Facade** | `Rte_Read()` / `Rte_Write()` — a few dozen functions that hide the entire BSW complexity. |
| 🔴 | **Template Method** | SWC Template in ARXML defines fixed skeleton (Runnables, Ports, DataElements) with user-filled specifics. |
| 🔴 | **Decorator** | Protocol stack layering: CanTp decorates CanIf with segmentation, CanNm decorates with network management. |
| 🟡 | **Singleton** | EcuM, BswM, OS — one per ECU per definition. |
| 🟡 | **Factory Method** | MCAL vendors provide chip-specific factory code; upper layers remain chip-agnostic. |
| 🟡 | **Builder** | Code generators build output in steps (header → source → init → runtime code). Manifest builders in Adaptive. |
| 🟡 | **Command** | Diagnostic request/response (UDS) — each request encapsulated as a Command with defined effects. |
| 🟡 | **Memento** | DEM stores DTC snapshots (freeze frames) — a Memento of the fault condition. |
| ⚪ | **Prototype** | Rare in Classic AUTOSAR. Clone-able SWC instances in Adaptive via dynamic deployment. |
| ⚪ | **Bridge** | Algorithm vs platform separation — same control algorithm, different MCU implementations. |
| ⚪ | **Iterator** | NvM block iteration, DTC history traversal. |
| ⚪ | **Flyweight** | Shared calibration tables (XCP/CCP) — same parameter set referenced by many SWCs. |
| ⚪ | **Interpreter** | XCP/CCP protocol parsing, UDS session logic. |
| ⚪ | **Visitor** | ARXML model transformation tools (e.g., adding a port to all SWCs of a type). |
| ⚪ | **Proxy** (dup) | Already covered — also applies to BSW scheduler services. |

---

## Classic AUTOSAR: Per-Layer Pattern Map

### Application Layer (SWCs)

```
┌───────────────────────────────────────┐
│  SWC: BrakeController (Atomic)        │
│  ┌─────────────────────────────────┐  │
│  │  State: idle → apply → hold    │  │  ← State
│  │         → release → error      │  │
│  ├─────────────────────────────────┤  │
│  │  S/R: BrakePedalPosition        │  │  ← Observer (subscriber side)
│  │  C/S: GetWheelSpeed()           │  │
│  ├─────────────────────────────────┤  │
│  │  Runnable: BrakeLogic           │  │
│  └─────────────────────────────────┘  │
└───────────────────────────────────────┘
```

**Patterns in play here:**
- **State** — Every SWC with mode management (running/idle/error/sleep)
- **Observer** — S/R communication: one sender, N receivers auto-notified via RTE
- **Strategy** — Interchangeable algorithms behind same interface (e.g., `CalcTorque()` → economy/sport/track)

#### MBD (Simulink) Modeling Tips

- In Simulink, model SWC states using **Stateflow charts** (State pattern)
- Use **function-call subsystems** for Strategy injection
- The **Composition block** IS the Composite pattern
- Port interface definitions (.arxml) ARE the Template Method skeleton
- **Do NOT** model cross-SWC direct connections in Simulink — RTE handles routing; model only intra-SWC logic

### RTE Layer

The RTE is arguably the most pattern-dense single component in AUTOSAR.

```
┌─ RTE ──────────────────────────────────────────┐
│  Mediator ───────────────────────────────────┐  │
│  │  Route: SWC_A.Write(Speed) → SWC_B.Read()│  │
│  │  Route: SWC_A.Call(GetTemp) → SWC_C.Resp │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  Proxy ───────────────────────────────────────┐  │
│  │  Same ECU: direct function call           │  │
│  │  Cross ECU: CAN/LIN/ETH transport         │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  Facade ─────────────────────────────────────┐  │
│  │  Rte_Read() / Rte_Write() / Rte_Call()    │  │
│  │  ~20 functions hide entire BSW complexity │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

**Key insight:** RTE is auto-generated from ARXML. The patterns are baked into the **code generator**, not hand-coded. When troubleshooting RTE issues, understand which pattern your mapping falls into.

### BSW Layer

#### COM Stack — Chain of Responsibility

```
App SWC
   │
   ▼  Rte_Write()
┌──────┐   ┌─────────────────────┐
│ Com  │──▶│ Signal→PDU packing  │  ← each layer processes
└──┬───┘   └─────────────────────┘     or passes to next
   │
┌──────┐   ┌─────────────────────┐
│ PduR │──▶│ Route PDU to bus    │
└──┬───┘   └─────────────────────┘
   │
┌──────┐   ┌─────────────────────┐
│ CanIf│──▶│ CAN controller      │
└──┬───┘   │ abstraction         │
   │       └─────────────────────┘
┌──────┐   ┌─────────────────────┐
│CanDrv│──▶│ Hardware registers  │
└──────┘   └─────────────────────┘
   │
   ▼  CAN Bus
```

**Troubleshooting tip:** When a CAN message isn't sent, trace down the chain. If Com accepted it but CanDrv didn't send, the issue is likely PduR routing (not Com or CanDrv).

#### Protocol Stack — Decorator

```
CanIf (base frame-level service)
  └── CanTp (decorator: adds segmentation for large messages)
       └── CanNm (decorator: adds network management)
            └── PduR (routes to upper layers)
```

Each layer wraps the previous one, adding capabilities without modifying the underlying module.

#### Diagnostic Stack — Chain of Responsibility

```
External Tester (CAN/UDS)
   │
   ▼  0x22 F1 90 (ReadDataByIdentifier)
┌──────┐   checks: is this a valid SID?
│ Dcm  │──▶ routes to Dem or DSP
└──┬───┘
   │
┌──────┐   checks: is this event stored?
│ Dem  │──▶ look up DTC status
└──┬───┘
   │
┌──────┐   checks: is this function inhibited?
│ FiM  │──▶ return allowed/blocked
└──┬───┘
   │
┌──────────┐
│ SWC_Diag │──▶ execute diagnostic response
└──────────┘
```

---

## Adaptive AUTOSAR — OOP-Friendly Patterns

Adaptive AUTOSAR (C++17/20, POSIX, dynamic) enables richer OOP patterns:

| Pattern | Adaptive AUTOSAR Module | Implementation Detail |
|---------|------------------------|----------------------|
| **Proxy / Skeleton** | `ara::com` | The core communication model. Client creates `Proxy`, server creates `Skeleton`. Communication via SOME/IP. |
| **Observer** | `ara::com` Events | `Subscribe()` / `SetReceiveHandler()` — event-driven callback model |
| **Singleton** | `ara::exec`, `ara::per`, `ara::log` | Execution Manager, Persistency, Logging — all process-wide singletons |
| **Factory Method** | Manifest Parser | `MachineBuilder::Create()` → platform-specific implementation |
| **Builder** | Deployment Config | Step-by-step construction of deployment.json/manifest |
| **Strategy** | State Management | Different execution states (Startup/Shutdown/Running/Update) with switchable behaviors |
| **Mediator** | Communication Management | `ara::com` broker routing between processes and machines |

### Adaptive vs Classic — Pattern Shift

| | Classic AUTOSAR | Adaptive AUTOSAR |
|--|----------------|-----------------|
| Language | C (structs, function pointers) | C++ (classes, templates, smart pointers) |
| Communication | S/R implicit (RTE generated) | Explicit Proxy/Skeleton (ara::com) |
| State management | Stateflow → generated C | C++ State pattern (std::variant, polymorphism) |
| Configuration | ARXML static generation | Manifest JSON + runtime discovery |
| Key pattern enabler | Code generation | Runtime polymorphism |

---

## Role-Based Guidance

### "I'm a Simulink modeler" → Focus on

1. **State** — Your Stateflow charts ARE AUTOSAR mode managers. Understand how chart states map to SWC mode declarations.
2. **Observer** — Every S/R port you draw creates an Observer relationship in the generated RTE code.
3. **Composite** — Your model hierarchy (Composition → Atomic SWCs → Runnables) maps directly to the Composite pattern.
4. **Strategy** — Use variant subsystems or function-call subsystems to model switchable algorithms that map to multiple ARXML implementations.

### "I'm a BSW integrator" → Focus on

1. **Chain of Responsibility** — Trace COM stack and diagnostic stack. When a message is lost, walk the chain to find where it dropped.
2. **Decorator** — Protocol stacks (Tp, Nm, FrAr) are decorators. Understanding this makes config ordering intuitive.
3. **Adapter** — Your ECU Abstraction Layer job IS adapting MCAL to BSW.
4. **Facade** — RTE is your facade. Know its API boundaries so you know what's an RTE issue vs a BSW issue.

### "I'm writing an AUTOSAR code generator" → Focus on

1. **Builder** — Build output code in phases: declarations → definitions → init → runtime loop → shutdown.
2. **Template Method** — The SWC template (ports, runnables, timing events) is fixed; the generator fills it.
3. **Factory Method** — Platform-conditional code generation (ARM/AURIX/TriCore).
4. **Visitor** — ARXML model transformations (e.g., add XCP measurement ports to all SWCs matching a pattern).
