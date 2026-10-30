// Names translated for display only. No instructions, doses or clinical approval.
// Bound to the exact source identity/version and original title.
const catalogDisplayNames =
    <String, ({String version, String original, Map<String, String> names})>{
      "wger:movement:1027": (
        version:
            "275cc8298c767f80deb5db3b0996f09e0c083ae9d88fb4f66445cdd34017ae1b",
        original: "Elevated prayer stretch",
        names: {
          "pt": "Alongamento de oração com apoio elevado",
          "en": "Elevated prayer stretch",
          "es": "Estiramiento de oración con apoyo elevado",
        },
      ),
      "wger:movement:1028": (
        version:
            "117f408201d6106bea8ca352721e190f38c1cae5ba7c7a8acc0998d0aa9c3123",
        original: "Quadruped thoracic rotation left",
        names: {
          "pt": "Rotação torácica em quatro apoios à esquerda",
          "en": "Quadruped thoracic rotation left",
          "es": "Rotación torácica en cuadrupedia a la izquierda",
        },
      ),
      "wger:movement:1029": (
        version:
            "578bd5bf8711044f15756d3e07326c547307f90c066f58153e007501e27bfcfa",
        original: "Quadruped thoracic rotation right",
        names: {
          "pt": "Rotação torácica em quatro apoios à direita",
          "en": "Quadruped thoracic rotation right",
          "es": "Rotación torácica en cuadrupedia a la derecha",
        },
      ),
      "wger:movement:1080": (
        version:
            "b18af3b6d8e98beb14f7ea675d746b7974b2f41eb2fa97309876d767bb63f2fb",
        original: "Hindu Pushups",
        names: {
          "pt": "Flexão hindu",
          "en": "Hindu Pushups",
          "es": "Flexiones hindúes",
        },
      ),
      "wger:movement:1081": (
        version:
            "b24533a1f72252b98fe822e6355479c6f4b88d44a7121f2797a5b8f27a6deec5",
        original: "Shoulder dislocates",
        names: {
          "pt": "Mobilidade dos ombros (shoulder dislocates)",
          "en": "Shoulder dislocates",
          "es": "Dislocaciones de hombros",
        },
      ),
      "wger:movement:1082": (
        version:
            "9c1ac9618e4230b80e76102f198e146031317aeb2bc45d3357025069721ff5c3",
        original: "Bent over row to external rotation",
        names: {
          "pt": "Remada curvada com rotação externa",
          "en": "Bent over row to external rotation",
          "es": "Remo inclinado con rotación externa",
        },
      ),
      "wger:movement:1083": (
        version:
            "4fb80a96867e264c3f78c691d9b6b65b43f0ccb8910fb18b0a665c0efc59eb01",
        original: "YWTs",
        names: {
          "pt": "Elevações Y, W e T",
          "en": "YWTs",
          "es": "Elevaciones Y, W y T",
        },
      ),
      "wger:movement:1084": (
        version:
            "c542b78778e43a49b3626618ecafc152efc138520ae3980e39114e21aa0ffebf",
        original: "Dumbbell Floor Press",
        names: {
          "pt": "Supino com halteres no chão",
          "en": "Dumbbell Floor Press",
          "es": "Press con mancuernas en el suelo",
        },
      ),
      "wger:movement:1086": (
        version:
            "b60b3551cff35f5924c68de7d5710871b6f31d0ddc17526216f8b531bbae5d9d",
        original: "Close-grip Press-ups",
        names: {
          "pt": "Flexão com pegada fechada",
          "en": "Close-grip Press-ups",
          "es": "Flexiones con agarre cerrado",
        },
      ),
      "wger:movement:1087": (
        version:
            "fa1c98d421df117befe3df4c75a526353d7d0c4f3969fe02613dae75d8c774c7",
        original: "Dumbbell Hang Power Cleans",
        names: {
          "pt": "Power clean com halteres a partir da suspensão",
          "en": "Dumbbell Hang Power Cleans",
          "es": "Cargada de potencia con mancuernas desde suspensión",
        },
      ),
      "wger:movement:1088": (
        version:
            "386639d34b44726e14162159bbbfc3efb6a1ce9bb0acc89ecd3d9c794e55173e",
        original: "Dumbbell sumo deadlift",
        names: {
          "pt": "Levantamento terra sumô com halteres",
          "en": "Dumbbell sumo deadlift",
          "es": "Peso muerto sumo con mancuernas",
        },
      ),
      "wger:movement:1089": (
        version:
            "d822d4687131cb99b349a01c4648bf287770d16984f320e95a46f6c144a8fb92",
        original: "Medicine ball twist",
        names: {
          "pt": "Rotação com bola medicinal",
          "en": "Medicine ball twist",
          "es": "Giro con balón medicinal",
        },
      ),
      "wger:movement:1090": (
        version:
            "fb58775ff4b8398f5ad4c27d04819bc327e869286ce45c18201b5668143d031d",
        original: "Vpushup",
        names: {"pt": "Flexão em V", "en": "Vpushup", "es": "Flexiones en V"},
      ),
      "wger:movement:1091": (
        version:
            "38797b40e5d7b09def082a2b4fc7bc6a90b61eb42e7a93a0a95e56dc9c0c0c53",
        original: "Plank Shoulder Taps",
        names: {
          "pt": "Prancha com toques nos ombros",
          "en": "Plank Shoulder Taps",
          "es": "Plancha con toques de hombro",
        },
      ),
      "wger:movement:1092": (
        version:
            "0ddb41ad3945e823bb8223da1b9e89c28d062f135874b7a4461e00176ea11db2",
        original: "Bag training",
        names: {
          "pt": "Treino com saco",
          "en": "Bag training",
          "es": "Entrenamiento con saco",
        },
      ),
      "wger:movement:1093": (
        version:
            "05f7e9457a4055637483d8f1e96da7a812b8dac57e62270e1627a8f36195ee6f",
        original: "Rowing Machine",
        names: {
          "pt": "Remo na máquina",
          "en": "Rowing Machine",
          "es": "Máquina de remo",
        },
      ),
      "wger:movement:1094": (
        version:
            "49a34a6a8a9b377ff4dccb1f15e5a515117fa8498d14313eedaf919448a41ba7",
        original: "Seated Bench Press",
        names: {
          "pt": "Supino sentado",
          "en": "Seated Bench Press",
          "es": "Press de pecho sentado",
        },
      ),
      "wger:movement:1096": (
        version:
            "8dde366ebf05de986ee307fb07dafb7bb86b7d7163dbdb6c22a7a2a0e60ad706",
        original: "Abduction while standing",
        names: {
          "pt": "Abdução em pé",
          "en": "Abduction while standing",
          "es": "Abducción de pie",
        },
      ),
      "wger:movement:1098": (
        version:
            "cc04028967ad59703dc5225627eebe8d0828be9e6afa2abbf0149b97d0afe168",
        original: "Seated rear delt rise",
        names: {
          "pt": "Elevação para deltoide posterior sentado",
          "en": "Seated rear delt rise",
          "es": "Elevación de deltoides posterior sentado",
        },
      ),
      "wger:movement:1099": (
        version:
            "1f2e54fa249a5528efddc00c47d5df9f5788424fee414c7dfba59ed07447df8e",
        original: "Dynamic side hold",
        names: {
          "pt": "Sustentação lateral dinâmica",
          "en": "Dynamic side hold",
          "es": "Sostén lateral dinámico",
        },
      ),
      "wger:movement:1100": (
        version:
            "b9e8c3b663056428dbfbed81dc9fb5244d3a1fce36113d7b7669fae292c4fedf",
        original: "Wall balls",
        names: {
          "pt": "Lançamento de bola na parede",
          "en": "Wall balls",
          "es": "Lanzamiento de balón a la pared",
        },
      ),
      "wger:movement:1101": (
        version:
            "4d5fe2c731bd689430387dd426533690d59a4b16b0edcf60a54dd95ee1b728e4",
        original: "Horizontal traction isometry",
        names: {
          "pt": "Tração horizontal isométrica",
          "en": "Horizontal traction isometry",
          "es": "Tracción horizontal isométrica",
        },
      ),
      "wger:movement:1102": (
        version:
            "cc0af4326d641cc007b26b2d21f307b56c9b54a977babbfcbd2c04c96146612d",
        original: "Alternate back lunges",
        names: {
          "pt": "Afundo para trás alternado",
          "en": "Alternate back lunges",
          "es": "Zancadas hacia atrás alternas",
        },
      ),
      "wger:movement:1103": (
        version:
            "c6bcb0219bc93de792baee878892db4c3563ca389a86730b6c69521b3695e2f1",
        original: "walking bridge",
        names: {
          "pt": "Ponte com caminhada",
          "en": "walking bridge",
          "es": "Puente con marcha",
        },
      ),
      "wger:movement:12": (
        version:
            "3fc00c7931bd4b35cbf6620f52807e4c4f85e71764ffa660639494afd96430dc",
        original: "Seated Hip Adduction",
        names: {
          "pt": "Adução de quadril sentado",
          "en": "Seated Hip Adduction",
          "es": "Aducción de cadera sentado",
        },
      ),
      "wger:movement:1638": (
        version:
            "b9382f503e96fd607cff3fec165aca7a888cab10885e77a524cb4e8cdbd6b4eb",
        original: "Barbell Clean and press",
        names: {
          "pt": "Clean e desenvolvimento com barra",
          "en": "Barbell Clean and press",
          "es": "Cargada y press con barra",
        },
      ),
      "wger:movement:1639": (
        version:
            "12e0752a10e499ca148fd6bcd29cdf913299381f8fc660e47a3f8afa636ebbe7",
        original: "Dumbbell Bent Over Face Pull",
        names: {
          "pt": "Puxada ao rosto com halteres, tronco inclinado",
          "en": "Dumbbell Bent Over Face Pull",
          "es": "Tirón a la cara con mancuernas y tronco inclinado",
        },
      ),
      "wger:movement:1640": (
        version:
            "a622229145238fedc6bd3b2ed203b6ccc4665577f4873ee1cc3161b7ebf91c30",
        original: "Dumbbell Front Squat",
        names: {
          "pt": "Agachamento frontal com halteres",
          "en": "Dumbbell Front Squat",
          "es": "Sentadilla frontal con mancuernas",
        },
      ),
      "wger:movement:1641": (
        version:
            "402a8a227c85070ab944f87caea91b6b40984d2eacf83a37efe327d2fe970f76",
        original: "Kettlebell One Legged Deadlift",
        names: {
          "pt": "Levantamento terra unilateral com kettlebell",
          "en": "Kettlebell One Legged Deadlift",
          "es": "Peso muerto a una pierna con kettlebell",
        },
      ),
      "wger:movement:1642": (
        version:
            "ff0f21b241ed5d8be751f2cee3a59d2525f3823f7daa27ad71ca441057d99ee2",
        original: "Dumbbell Hip Thrust",
        names: {
          "pt": "Elevação de quadril com haltere",
          "en": "Dumbbell Hip Thrust",
          "es": "Elevación de cadera con mancuerna",
        },
      ),
      "wger:movement:1648": (
        version:
            "178568790325a2f791403f4fc918439778f909e7f7b83b67b0244551204ae230",
        original: "Weighted Crunch",
        names: {
          "pt": "Abdominal com peso",
          "en": "Weighted Crunch",
          "es": "Abdominal con peso",
        },
      ),
      "wger:movement:1650": (
        version:
            "866d264c29c00458ab1965811b6218b90c70f12ef6120c8e199c582b572008e4",
        original: "Dumbbell Side Bend",
        names: {
          "pt": "Flexão lateral com haltere",
          "en": "Dumbbell Side Bend",
          "es": "Flexión lateral con mancuerna",
        },
      ),
      "wger:movement:1651": (
        version:
            "559df843165d16c162ffbdbca9b4b6c7b109c3976f331425cf1b2b935171838e",
        original: "Dumbbell Rear Lunge",
        names: {
          "pt": "Afundo para trás com halteres",
          "en": "Dumbbell Rear Lunge",
          "es": "Zancada hacia atrás con mancuernas",
        },
      ),
      "wger:movement:1652": (
        version:
            "da34491fce0325e8438064c6d8c4546df1395ecaa5df632ce6f934915e4e1ec0",
        original: "Dumbbell Romanian Deadlift",
        names: {
          "pt": "Levantamento terra romeno com halteres",
          "en": "Dumbbell Romanian Deadlift",
          "es": "Peso muerto rumano con mancuernas",
        },
      ),
      "wger:movement:1653": (
        version:
            "8e910161230a2443afff6c4fafb601dc2c9a4cde6629459a165b8150733fc8c3",
        original: "Dumbbell Side Squat",
        names: {
          "pt": "Agachamento lateral com haltere",
          "en": "Dumbbell Side Squat",
          "es": "Sentadilla lateral con mancuerna",
        },
      ),
      "wger:movement:1654": (
        version:
            "e595c4925a817f7e65394cb7290b455001856e74fb0d87182eac34c2f9b435d8",
        original: "Elevação lateral na mãquina",
        names: {
          "pt": "Elevação lateral na máquina",
          "en": "Machine lateral raise",
          "es": "Elevación lateral en máquina",
        },
      ),
      "wger:movement:1656": (
        version:
            "4f33054e155e83039f9fb2a6edeb9b668c38eb0bae0a586260643949d51807cb",
        original: "Cable Chest Press - Decline",
        names: {
          "pt": "Supino declinado no cabo",
          "en": "Cable Chest Press - Decline",
          "es": "Press de pecho declinado en polea",
        },
      ),
      "wger:movement:1657": (
        version:
            "d75ee494ed396b6c398bad96766d7c98afba07e1dc93016ef8020c4ad8d7d9ec",
        original: "Preacher Curl - Internally Rotated",
        names: {
          "pt": "Rosca Scott com rotação interna",
          "en": "Preacher Curl - Internally Rotated",
          "es": "Curl predicador con rotación interna",
        },
      ),
      "wger:movement:1658": (
        version:
            "d7a65a55e51b892d3bb63a9ade48653997a091856c1269f97e20deb91e31d654",
        original: "Preacher Curl - Externally Rotated",
        names: {
          "pt": "Rosca Scott com rotação externa",
          "en": "Preacher Curl - Externally Rotated",
          "es": "Curl predicador con rotación externa",
        },
      ),
      "wger:movement:1659": (
        version:
            "f895ef7248be13089706553849a519f95f30bdae1dc5da58077260484794814e",
        original: "Lat Pulldown - Cross Body Single Arm",
        names: {
          "pt": "Puxada unilateral cruzada",
          "en": "Lat Pulldown - Cross Body Single Arm",
          "es": "Jalón unilateral cruzado",
        },
      ),
      "wger:movement:1660": (
        version:
            "c858c5d9ba0eb003b18a368a31617027ee6386f3f0ecb19ec23bae2223274e24",
        original: "Cable Chest Press - Incline",
        names: {
          "pt": "Supino inclinado no cabo",
          "en": "Cable Chest Press - Incline",
          "es": "Press de pecho inclinado en polea",
        },
      ),
      "wger:movement:1661": (
        version:
            "2fa6a491cf1fc362984792afe2600fe6da3adc64a5eb60a98f75db8a2eec2431",
        original: "Cable Triceps Press",
        names: {
          "pt": "Extensão de tríceps no cabo",
          "en": "Cable Triceps Press",
          "es": "Extensión de tríceps en polea",
        },
      ),
      "wger:movement:1662": (
        version:
            "1c2f142095d4019c8ff5f352c36bb75768c0cfd748f13bf224f52463e798eb26",
        original: "Cable Tri Extension - Internal Rotation",
        names: {
          "pt": "Extensão de tríceps no cabo com rotação interna",
          "en": "Cable Tri Extension - Internal Rotation",
          "es": "Extensión de tríceps en polea con rotación interna",
        },
      ),
      "wger:movement:1666": (
        version:
            "2d4e315c37960ff0c3e5de1efb62d81a6c93107f38281d055639e7814c1a16a9",
        original: "Curl  - With Shoulder Elevated",
        names: {
          "pt": "Rosca com ombro elevado",
          "en": "Curl  - With Shoulder Elevated",
          "es": "Curl con hombro elevado",
        },
      ),
      "wger:movement:1668": (
        version:
            "9443bc5305f5f0a9a35ecb5ba2477c39355545ece15fce5823a787eb5fd449be",
        original: "One Arm Overhead Cable Tricep Extension",
        names: {
          "pt": "Extensão unilateral de tríceps acima da cabeça no cabo",
          "en": "One Arm Overhead Cable Tricep Extension",
          "es": "Extensión unilateral de tríceps sobre la cabeza en polea",
        },
      ),
      "wger:movement:1672": (
        version:
            "02c66a1dc79e2c60094aac83109128735d6440c9ea5d7b0fada69f5af44fbff0",
        original: "Seated Hip Abduction",
        names: {
          "pt": "Abdução de quadril sentado",
          "en": "Seated Hip Abduction",
          "es": "Abducción de cadera sentado",
        },
      ),
      "wger:movement:1679": (
        version:
            "82ab2212ebd986741e4027eb763fcb1019e0abe17fae3dcbdf4bdf20e1da2f7b",
        original: "Wall Angels",
        names: {
          "pt": "Anjo na parede",
          "en": "Wall Angels",
          "es": "Ángeles en la pared",
        },
      ),
      "wger:movement:1680": (
        version:
            "491cf093f61d689de785c214ce25c1ac9c65ef511d6d3bc3eb3a60929dbab52d",
        original: "seated figure four",
        names: {
          "pt": "Alongamento em quatro sentado",
          "en": "seated figure four",
          "es": "Estiramiento en cuatro sentado",
        },
      ),
      "wger:movement:1683": (
        version:
            "954efcdc59eedeb868e65afd78fa82f425ec4c210915644d0daf42ce43a4c138",
        original: "Zottman curl",
        names: {
          "pt": "Rosca Zottman",
          "en": "Zottman curl",
          "es": "Curl Zottman",
        },
      ),
      "wger:movement:20": (
        version:
            "55950f7546f859d3d663d43a8d0af7ead0c95e8f067d050c74df440dbfe92681",
        original: "Arnold Shoulder Press",
        names: {
          "pt": "Desenvolvimento Arnold",
          "en": "Arnold Shoulder Press",
          "es": "Press Arnold",
        },
      ),
      "wger:movement:31": (
        version:
            "4985219b7ec1b0114de485cea8a941410041ffc54e8758ac1e1ddbf5daa565e7",
        original: "Axe Hold",
        names: {
          "pt": "Sustentação do machado",
          "en": "Axe Hold",
          "es": "Sostén del hacha",
        },
      ),
      "wger:movement:41": (
        version:
            "81d9f641ea0faaf1fd5f08cd00e6b039f7ff2bc91a6fcb6e307753cc0e8abd79",
        original: "Barbell Ab Rollout",
        names: {
          "pt": "Rolamento abdominal com barra",
          "en": "Barbell Ab Rollout",
          "es": "Rueda abdominal con barra",
        },
      ),
      "wger:movement:43": (
        version:
            "40894a9a5ae00d936b975ef354bca353bbbba51cfd9b8895c9bf34145b884526",
        original: "Barbell Hack Squats",
        names: {
          "pt": "Agachamento Hack com barra",
          "en": "Barbell Hack Squats",
          "es": "Sentadilla Hack con barra",
        },
      ),
      "wger:movement:46": (
        version:
            "9813717f4100a18beaa33ec32c4b35cc5ed773d6ab983c3fcc63282c52a96d07",
        original: "Barbell Lunges Standing",
        names: {
          "pt": "Afundo em pé com barra",
          "en": "Barbell Lunges Standing",
          "es": "Zancadas de pie con barra",
        },
      ),
      "wger:movement:48": (
        version:
            "8223d87b0a0aa3472c04b4fc7104174758da95332da62e31770a270cc6a4147d",
        original: "Barbell Reverse Wrist Curl",
        names: {
          "pt": "Extensão de punhos com barra",
          "en": "Barbell Reverse Wrist Curl",
          "es": "Extensión de muñecas con barra",
        },
      ),
      "wger:movement:50": (
        version:
            "4c27f18e773f3a211d45bac8abc9da5e335efb97612ac7ec88d48ef596446c9a",
        original: "Barbell Triceps Extension",
        names: {
          "pt": "Extensão de tríceps com barra",
          "en": "Barbell Triceps Extension",
          "es": "Extensión de tríceps con barra",
        },
      ),
      "wger:movement:51": (
        version:
            "0fe5c4cdf682cce85c624c719bea3a75d0833e628a3a85da6c20631c350ce6a0",
        original: "Flexão de Punho com Barra",
        names: {
          "pt": "Flexão de punho com barra",
          "en": "Barbell wrist curl",
          "es": "Flexión de muñeca con barra",
        },
      ),
      "wger:movement:56": (
        version:
            "2d8756f84fbecf1b53227e3ee92f8a0805467523e001942b5a85c5f4c3ad4b27",
        original: "Abdominal Stabilization",
        names: {
          "pt": "Estabilização abdominal",
          "en": "Abdominal Stabilization",
          "es": "Estabilización abdominal",
        },
      ),
      "wger:movement:57": (
        version:
            "3c8f47c2e494adca961aec4982fa3bb35341faed978e522c5c0052b54281857a",
        original: "Bear Walk 2",
        names: {
          "pt": "Caminhada do urso 2",
          "en": "Bear Walk 2",
          "es": "Marcha del oso 2",
        },
      ),
      "wger:movement:71": (
        version:
            "6acf4147e48fa1c28ed647c06be5d7a11ab925330db9fd7fbb55e2664e8d8633",
        original: "Single Leg Extension",
        names: {
          "pt": "Extensão unilateral de joelho",
          "en": "Single Leg Extension",
          "es": "Extensión de rodilla a una pierna",
        },
      ),
      "wger:movement:73": (
        version:
            "0b90969c3382967622b1affc114fcfe99f1b904dffe413aff4eb188c5572d16a",
        original: "Bench Press",
        names: {
          "pt": "Supino com barra",
          "en": "Bench Press",
          "es": "Press de banca con barra",
        },
      ),
      "wger:movement:75": (
        version:
            "eddf8ef683c199bfaf5fa0a42ec4b845701f7823204385298172214094e6fabf",
        original: "Supino com halteres",
        names: {
          "pt": "Supino com halteres",
          "en": "Dumbbell bench press",
          "es": "Press de banca con mancuernas",
        },
      ),
      "wger:movement:76": (
        version:
            "44757be41221034565e0d40ae5107de35718617d815da22e74b904a95bcab6fc",
        original: "Bench Press Narrow Grip",
        names: {
          "pt": "Supino com pegada fechada",
          "en": "Bench Press Narrow Grip",
          "es": "Press de banca con agarre cerrado",
        },
      ),
      "wger:movement:79": (
        version:
            "6d492b96f534981522c284957a02888363149174a36830cd44006d84499f9ce4",
        original: "Bent High Pulls",
        names: {
          "pt": "Puxada alta com tronco inclinado",
          "en": "Bent High Pulls",
          "es": "Tirón alto con tronco inclinado",
        },
      ),
      "wger:movement:81": (
        version:
            "6ad7cb58c5342c3e34933bdb8dc3ce76b28900faee44b56998721374285a6811",
        original: "Bent Over Dumbbell Rows (Single Arm)",
        names: {
          "pt": "Remada unilateral com haltere",
          "en": "Bent Over Dumbbell Rows (Single Arm)",
          "es": "Remo con mancuerna a una mano",
        },
      ),
      "wger:movement:82": (
        version:
            "f159cab34637c9d0941a51f51b05ab1385dd224710b62bd70f1c14ce2c508a77",
        original: "Bent-over Lateral Raises",
        names: {
          "pt": "Elevação lateral com tronco inclinado",
          "en": "Bent-over Lateral Raises",
          "es": "Elevaciones laterales con tronco inclinado",
        },
      ),
      "wger:movement:83": (
        version:
            "d8aff0ee2d951450a860c6eec669326943cf9e9111d55ff967f23b9e10a58bf9",
        original: "Remada Curvada",
        names: {
          "pt": "Remada curvada",
          "en": "Bent-over row",
          "es": "Remo inclinado",
        },
      ),
      "wger:movement:84": (
        version:
            "45f7a78b2b04ab960e45733326317f04e958c8463c4d173f6d55d20fccbc7a0c",
        original: "Bent Over Rowing Reverse",
        names: {
          "pt": "Remada curvada com pegada invertida",
          "en": "Bent Over Rowing Reverse",
          "es": "Remo inclinado con agarre invertido",
        },
      ),
      "wger:movement:9": (
        version:
            "0a9f08f6e4b07ee961070e4317106eda5920d5122b33971aa234136128c1d19e",
        original: "2 Handed Kettlebell Swing",
        names: {
          "pt": "Balanço de kettlebell com duas mãos",
          "en": "2 Handed Kettlebell Swing",
          "es": "Balanceo de kettlebell con dos manos",
        },
      ),
      "wger:movement:91": (
        version:
            "fb34c1bc0768803183b9ff36455ff097a762939064d243c3d7c906c09b9af184",
        original: "Rosca direta com barra reta",
        names: {
          "pt": "Rosca direta com barra reta",
          "en": "Straight barbell curl",
          "es": "Curl de bíceps con barra recta",
        },
      ),
      "wger:movement:92": (
        version:
            "69674d102bf8f8d2867ad6ee25b1c440bf9b36ddaa4a69759384ec0dfdeeb267",
        original: "Biceps Curls With Dumbbell",
        names: {
          "pt": "Rosca de bíceps com haltere",
          "en": "Biceps Curls With Dumbbell",
          "es": "Curl de bíceps con mancuerna",
        },
      ),
      "wger:movement:94": (
        version:
            "99701a5f983b314a7ecb222f4fa12951a6a8020652e66c6839aa111cf98fd8ce",
        original: "Biceps Curls With SZ-bar",
        names: {
          "pt": "Rosca de bíceps com barra W",
          "en": "Biceps Curls With SZ-bar",
          "es": "Curl de bíceps con barra EZ",
        },
      ),
      "wger:movement:95": (
        version:
            "bfdadae7c611d6a606027c088f6ab10b59945900eff9d911000d9d6cf7fa7f73",
        original: "Biceps Curl With Cable",
        names: {
          "pt": "Rosca de bíceps no cabo",
          "en": "Biceps Curl With Cable",
          "es": "Curl de bíceps en polea",
        },
      ),
    };
String catalogSearchTerm(String value) {
  final q = value.trim().toLowerCase();
  const terms = {
    'supino': 'press',
    'flexão': 'push',
    'flexao': 'push',
    'agachamento': 'squat',
    'alongamento': 'stretch',
    'remada': 'row',
    'rosca': 'curl',
    'tríceps': 'triceps',
    'triceps': 'triceps',
    'abdominal': 'ab',
    'sentadilla': 'squat',
    'estiramiento': 'stretch',
    'flexiones': 'push',
    'remo': 'row',
    'bíceps': 'biceps',
  };
  if (terms.containsKey(q)) return terms[q]!;
  for (final r in catalogDisplayNames.values) {
    if (r.names.values.any((name) => name.toLowerCase() == q)) {
      return r.original;
    }
  }
  return value;
}
