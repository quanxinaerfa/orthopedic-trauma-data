# Diagnosis Keyword Matching Dictionary

This document provides full transparency for the keyword-matching algorithm
used to classify Chinese free-text diagnoses into analytic categories. The
algorithm has not been formally validated against gold-standard manual coding
(this is acknowledged as a limitation in the manuscript), but the complete
mapping rules are documented below to enable third-party scrutiny and
replication.

## Algorithm priority order

Diagnoses are evaluated against keyword lists in the following order, with
the first matching category assigned:

1. **Hardware-related procedures** (highest priority)
2. **Degenerative diseases** (excluded if fracture also present)
3. **Spine/pelvis fractures**
4. **Lower-limb fractures**
5. **Upper-limb fractures**
6. **Other** (default if no match)

## Category 1: Hardware-related procedures (内固定相关手术)

Triggered by any of the following keywords:

| Chinese keyword | English meaning |
|---|---|
| 内固定取出 | Internal fixation removal |
| 钢板取出 | Plate removal |
| 螺钉取出 | Screw removal |
| 髓内钉取出 | Intramedullary nail removal |
| 克氏针取出 | Kirschner wire removal |

**Note**: This category may include heterogeneous indications including
planned routine removal, infection-related removal, or implant failure.
The dataset does not allow disambiguation; this is acknowledged as a
limitation in the manuscript.

## Category 2: Degenerative diseases (退变性疾病)

Triggered by these keywords (only if no fracture keywords present):

| Chinese keyword | English meaning |
|---|---|
| 颈椎病 | Cervical spondylosis |
| 椎间盘 | Intervertebral disc disease |
| 膝骨关节炎 | Knee osteoarthritis |
| 髋关节炎 | Hip arthritis |
| 骨关节炎 | Osteoarthritis (general) |
| 腰椎管狭窄 | Lumbar spinal stenosis |
| 椎管狭窄 | Spinal canal stenosis |

## Category 3: Spine/pelvis fractures (脊柱/骨盆)

| Chinese keyword | English meaning |
|---|---|
| 腰椎 | Lumbar vertebra |
| 胸椎 | Thoracic vertebra |
| 颈椎 | Cervical vertebra |
| 脊柱 | Spine |
| 椎体 | Vertebral body |
| 骨盆 | Pelvis |
| 骶骨 | Sacrum |

## Category 4: Lower-limb fractures (下肢) — INCLUDES SYNONYM AGGREGATION

**Important**: Multiple synonyms map here to handle terminology shifts
during the study period. See the "Known terminology variations" section
below for examples.

| Chinese keyword | English meaning |
|---|---|
| 股骨 | Femur (general) |
| 胫骨 | Tibia |
| 腓骨 | Fibula |
| 胫腓骨 | Tibia-fibula combination |
| 跟骨 | Calcaneus |
| 距骨 | Talus |
| 髌骨 | Patella |
| 踝 | Ankle |
| 足 | Foot |
| 胫骨平台 | Tibial plateau |
| 髋关节 | Hip joint |

## Category 5: Upper-limb fractures (上肢) — INCLUDES SYNONYM AGGREGATION

| Chinese keyword | English meaning |
|---|---|
| 桡骨 | Radius (general) |
| 尺骨 | Ulna |
| 尺桡骨 | Ulna-radius combination |
| 肱骨 | Humerus |
| 肩胛 | Scapula |
| 锁骨 | Clavicle |
| 腕骨 | Carpal bones |
| 掌骨 | Metacarpals |
| 指骨 | Phalanges |
| 肩关节 | Shoulder joint |
| 肘关节 | Elbow joint |

## Known terminology variations (transparency)

Two specific terminology shifts occurred during the study period that
required explicit synonym aggregation:

### Tibial plateau fractures (2017–2018 coding shift)
The diagnostic term "胫骨平台骨折" (tibial plateau fracture) appeared as
a near-zero count during 2017–2018, with affected cases plausibly recorded
under the following synonyms:

- `胫骨骨折` (tibial fracture, general)
- `胫腓骨骨折` (tibiofibular fracture)
- `闭合性胫骨骨折` (closed tibial fracture)

**Mitigation**: All tibia-related diagnoses were aggregated to the parent
category "下肢" (lower-limb fractures) for time-series analyses.
Condition-specific trend analysis for tibial plateau fractures was avoided.

### Distal radius fractures (~2021 coding shift)
A terminology shift around 2021 affected "桡骨远端骨折" (distal radius
fracture), with affected cases potentially recorded as:

- `桡骨骨折` (radial fracture, general)
- `桡骨下段骨折` (distal-segment radius fracture)
- `尺桡骨骨折` (radioulnar fracture)

**Mitigation**: All radius/ulna diagnoses were aggregated to "上肢"
(upper-limb fractures) for time-series analyses. Condition-specific trend
analysis for distal radius fractures was avoided.

## Fracture identification (是否骨折)

A binary "is_fracture" flag is also derived from the diagnosis text using
these keywords:

| Chinese keyword | English meaning |
|---|---|
| 骨折 | Fracture |
| 骨裂 | Bone crack |
| 粉碎性 | Comminuted |
| 粗隆间 | Intertrochanteric |
| 股骨颈 | Femoral neck |
| 椎体压缩 | Vertebral compression |

## Limitations of this algorithm

1. **No formal validation**: The algorithm has not been validated against
   independent dual manual coding, which would be the gold standard.
2. **Non-differential misclassification**: Misclassification is expected
   to be non-differential with respect to patient origin (the primary
   exposure in the equity analysis), so it is unlikely to bias the equity
   findings systematically — but it cannot be excluded.
3. **Fine-grained categories not reliable**: Sub-anatomical or
   mechanism-specific subgroups (e.g., displaced vs non-displaced) cannot
   be reliably extracted.
4. **Terminology shifts**: Two known shifts (tibial plateau, distal radius)
   are described above; other unrecognised shifts may exist.

## Reproducing the classification

The full algorithm is implemented in `R/02_diagnosis_classification.R`.
Running that script on the cleaned dataset reproduces all category
assignments deterministically.
