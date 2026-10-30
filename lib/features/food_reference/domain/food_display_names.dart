// Exact-version UI translations; source food identity, preparation and nutrients are unchanged.
const foodDisplayNames =
    <String, ({String version, String original, Map<String, String> names})>{
      "food:45094bf5dd6b5e29fbf72b717b860dcc6b75ebf1e2a734cc8f4b142b153c513f": (
        version:
            "fa6176939173421d44b61aa3c43ff598c5a976c70d864b7255bfa0bd34c4447c",
        original:
            "Rice, white, long grain, easy cook, boiled in unsalted water",
        names: {
          "pt":
              "Arroz branco, grão longo, cozimento fácil, cozido em água sem sal",
          "es":
              "Arroz blanco de grano largo, cocción fácil, hervido en agua sin sal",
          "en": "Rice, white, long grain, easy cook, boiled in unsalted water",
        },
      ),
      "food:7067261a75397f176d2a55f8383ea8341c197d75b9c8f3c1a40c988cb9835646": (
        version:
            "0aff76ce501712e97b4da68f3de0252cb4d70d829fcd6e19f86a6001540fb68c",
        original: "Rice, white, long grain, boiled in unsalted water",
        names: {
          "pt": "Arroz branco, grão longo, cozido em água sem sal",
          "es": "Arroz blanco de grano largo, hervido en agua sin sal",
          "en": "Rice, white, long grain, boiled in unsalted water",
        },
      ),
      "food:7088b3332cc59fb1c0f4460d47e9724737bbad86cd75a98c82a7dc5c4b055d6d": (
        version:
            "1080f70be08bbafcbc53d6d19578cb8b2d5cad2ccd52507e6f86a383eaa3b947",
        original: "Rice, white, long grain, raw",
        names: {
          "pt": "Arroz branco, grão longo, cru",
          "es": "Arroz blanco de grano largo, crudo",
          "en": "Rice, white, long grain, raw",
        },
      ),
      "food:8e2aa02f271a2b93dfb5906b3cf575714344290dde0c8395f976045bb1473318": (
        version:
            "6f92e103968d0794f3e73c93a27cf4d4ff3a07ae3f2bb11e10902b81d4e1f9d8",
        original: "Rice, white, Italian Arborio risotto, raw",
        names: {
          "pt": "Arroz branco italiano Arborio para risoto, cru",
          "es": "Arroz blanco italiano Arborio para risotto, crudo",
          "en": "Rice, white, Italian Arborio risotto, raw",
        },
      ),
      "food:989ee28efc65c9647b7a40324d5ef8ab1214191ac5d973e16befbad857b4f580": (
        version:
            "92b5dcc63f43f164df38162fc54662faefdd0e4f0de35b14ff6b15517f998fca",
        original: "Rice, white, basmati, raw",
        names: {
          "pt": "Arroz branco basmati, cru",
          "es": "Arroz blanco basmati, crudo",
          "en": "Rice, white, basmati, raw",
        },
      ),
      "food:a30f24228a25f7944c5663bd132ecdbfdaabcf86912b40c8361534c784a39021": (
        version:
            "a41bf7832dd126b21cd290756346b6e76fcdba57bdbbe853d2e6bc55d479529f",
        original: "Rice, white, basmati, easy cook, boiled in unsalted water",
        names: {
          "pt": "Arroz branco basmati, cozimento fácil, cozido em água sem sal",
          "es": "Arroz blanco basmati, cocción fácil, hervido en agua sin sal",
          "en": "Rice, white, basmati, easy cook, boiled in unsalted water",
        },
      ),
      "food:b03979158b6adf4c0f384c3459930a695f0691dab3abef40aed8ad90fb523e00": (
        version:
            "3d991ec429a738fae25777c575407939ff5a7d28a0d19acc296a9ba1fe4bdf05",
        original: "Rice, white, basmati, boiled in unsalted water",
        names: {
          "pt": "Arroz branco basmati, cozido em água sem sal",
          "es": "Arroz blanco basmati, hervido en agua sin sal",
          "en": "Rice, white, basmati, boiled in unsalted water",
        },
      ),
      "food:db478a20ed6d8fa27b5291be42e82692ab6cb3f8b4242ecbae79864fd2f9fea3": (
        version:
            "6e5b733879ed8584f783b55d3a430bbb65630f5844d1cdaea644fc0ccdeb46a6",
        original:
            "Rice, white, Italian \"Arborio\" risotto, boiled in unsalted water",
        names: {
          "pt":
              "Arroz branco italiano Arborio para risoto, cozido em água sem sal",
          "es":
              "Arroz blanco italiano Arborio para risotto, hervido en agua sin sal",
          "en":
              "Rice, white, Italian \"Arborio\" risotto, boiled in unsalted water",
        },
      ),
      "food:02d7d7473cfe173afb4e327443cca632fb92c9e5ae0bfcf75fd21db112b706b9": (
        version:
            "4fc536dc72f7d5dc293608d90e67d642fc21efb6498f0db4ec6f957da1a0e894",
        original: "Rice, brown, basmati, boiled in unsalted water",
        names: {
          "pt": "Arroz integral basmati, cozido em água sem sal",
          "es": "Arroz integral basmati, hervido en agua sin sal",
          "en": "Rice, brown, basmati, boiled in unsalted water",
        },
      ),
      "food:41d27b9f68bb1d541d648b9d0e3ced834f8eaf9ad04e8b8c7d7201ee360118e6": (
        version:
            "e4ddc003f1b1351fc30cf9988720d4981ac4fd68977e987a00d29960c064d283",
        original: "Rice, brown, easy cook, boiled in unsalted water",
        names: {
          "pt": "Arroz integral, cozimento fácil, cozido em água sem sal",
          "es": "Arroz integral, cocción fácil, hervido en agua sin sal",
          "en": "Rice, brown, easy cook, boiled in unsalted water",
        },
      ),
      "food:6e8fa3a75c85655b5fd39503564773681ac48c3882c1df5ea5db6eabceb21c39": (
        version:
            "6a09b6c7b15ba82331e9b8dc1138ade91f06f539da26180964c383d746021309",
        original: "Rice, brown, basmati, raw",
        names: {
          "pt": "Arroz integral basmati, cru",
          "es": "Arroz integral basmati, crudo",
          "en": "Rice, brown, basmati, raw",
        },
      ),
      "food:96e718c77883d7a561c6eb4cb3dcd670ca3dec569e263a98c8d96c90a8b4218c": (
        version:
            "95148493b608e3e16b7307b685df05ed9ed5ba2babf778c0dcfa2691ff8450ca",
        original: "Rice, brown, wholegrain, boiled in unsalted water",
        names: {
          "pt": "Arroz integral de grão inteiro, cozido em água sem sal",
          "es": "Arroz integral de grano entero, hervido en agua sin sal",
          "en": "Rice, brown, wholegrain, boiled in unsalted water",
        },
      ),
      "food:a2f02ca42efdc5041badd357ceaf2a3a62cf90d8735f077ae23685fbad409921": (
        version:
            "a7c9311638ad53d432ef8d75f04cfa07fe3c8ce57258f0db112bb0db76361a0e",
        original: "Salad, rice, brown",
        names: {
          "pt": "Salada de arroz integral",
          "es": "Ensalada de arroz integral",
          "en": "Salad, rice, brown",
        },
      ),
      "food:ccc1b6792c48992190932f4890aec3d6744d57f1a2e90f7ab5c8b74f0e69a042": (
        version:
            "480658f0a91986624312d53289a982875fdcc87a41556b63ad0be45d68deb467",
        original: "Rice, brown, easy cook, raw",
        names: {
          "pt": "Arroz integral, cozimento fácil, cru",
          "es": "Arroz integral, cocción fácil, crudo",
          "en": "Rice, brown, easy cook, raw",
        },
      ),
      "food:d7d22c1a015bc17a9526b694a9a8a2659915062d1f4dd32d357c58c72b11d73d": (
        version:
            "61566ef54a41591aad016311224193c8050d50d3afc8d1dd387b8e4cf2e5899a",
        original: "Rice, brown, wholegrain, raw",
        names: {
          "pt": "Arroz integral de grão inteiro, cru",
          "es": "Arroz integral de grano entero, crudo",
          "en": "Rice, brown, wholegrain, raw",
        },
      ),
      "food:1521bb217b0f5843afc348c2fc5868e91ef0eb0406791916093b58a51280b65d": (
        version:
            "128d427282faf5e0ec98c1dd130a23bd00aab1162a882389af75d9a01af13f79",
        original: "Beans, red kidney, canned in water, re-heated, drained",
        names: {
          "pt": "Feijão-vermelho, em conserva em água, reaquecido e escorrido",
          "es": "Alubias rojas, en conserva en agua, recalentadas y escurridas",
          "en": "Beans, red kidney, canned in water, re-heated, drained",
        },
      ),
      "food:d87e770732812daa3bd2447844bf42a3130d579426aceb76998d174e1402c65a": (
        version:
            "200e0242dec04d390e22521dda3e4faa32be2f3b153c899aeedfe67a7bfecece",
        original: "Beans, red kidney, dried, boiled in unsalted water",
        names: {
          "pt": "Feijão-vermelho seco, cozido em água sem sal",
          "es": "Alubias rojas secas, hervidas en agua sin sal",
          "en": "Beans, red kidney, dried, boiled in unsalted water",
        },
      ),
      "food:f88ccaf97961ab4d08c8355dea02c3d93c5e05b94aec75008c044e9ed53de216": (
        version:
            "62bf56857382f5acee5d336c54160236a06a83a7c1b6fa3d3c37398a4bf4d597",
        original: "Beans, red kidney, dried, raw",
        names: {
          "pt": "Feijão-vermelho seco, cru",
          "es": "Alubias rojas secas, crudas",
          "en": "Beans, red kidney, dried, raw",
        },
      ),
      "food:9581697b13e782046743de813bc743fca2e72b6285c65b278f3bcabe80432e78": (
        version:
            "7e38bd8e99b607459e119ea94818d20c48a84d435795ec48937d65217553a477",
        original: "Beans, blackeye, whole, dried, raw",
        names: {
          "pt": "Feijão-de-olho-preto inteiro, seco e cru",
          "es": "Frijoles de ojo negro enteros, secos y crudos",
          "en": "Beans, blackeye, whole, dried, raw",
        },
      ),
      "food:9e9d601a8dd7c25dc1da41a4895e9c5f3d9fddca0e04810878e9d1f5f7e9f7e7": (
        version:
            "8e44e30a6b1185140d72f1a6cde36a3af25ed444552485d6e177b95bf571a222",
        original: "Beans, blackeye, whole, dried, boiled in unsalted water",
        names: {
          "pt": "Feijão-de-olho-preto inteiro, seco e cozido em água sem sal",
          "es":
              "Frijoles de ojo negro enteros, secos y hervidos en agua sin sal",
          "en": "Beans, blackeye, whole, dried, boiled in unsalted water",
        },
      ),
      "food:259d596349938bed7bb4ac2ed75aae1f1a1cd88fda68681f5d9f8b74ff4111e2": (
        version:
            "008de25be3681ccf726d6fa937d02c0ec4237b562889dae22c5e1194feb350f5",
        original: "Riz blanc étuvé, cru",
        names: {
          "pt": "Arroz branco parboilizado, cru",
          "es": "Arroz blanco vaporizado, crudo",
          "en": "White parboiled rice, raw",
        },
      ),
      "food:5c499acdf6e7775d093e75961a45a07388842f4bbb865d2df11a0838f8c0fc72": (
        version:
            "d9071221228a4daaacc575cff3c193a4b9eb0fd31b3398383d77fab08fcc873b",
        original: "Riz blanc, cuit, sans sel ajouté",
        names: {
          "pt": "Arroz branco cozido, sem adição de sal",
          "es": "Arroz blanco cocido, sin sal añadida",
          "en": "White rice, cooked, no added salt",
        },
      ),
      "food:9c1ae3f2c49c39f8c866765b5b8c719c7878b9722c157223f6aa4bceeaa62786": (
        version:
            "d174b38453d1572682e73fae1d50e99fcd5c60fd42a65d5642cd0edc74e6ebae",
        original: "Riz blanc étuvé, cuit, sans sel ajouté",
        names: {
          "pt": "Arroz branco parboilizado cozido, sem adição de sal",
          "es": "Arroz blanco vaporizado cocido, sin sal añadida",
          "en": "White parboiled rice, cooked, no added salt",
        },
      ),
      "food:ae75dec8ee7d68091e0833af18658d8b766ec912b66c648b8375985d5f068b62": (
        version:
            "d895dd771f943b568db2af288df66d10c1959b2898edf8e2b910e9698c6173ce",
        original: "Riz blanc, précuit, cuit, sans sel ajouté",
        names: {
          "pt": "Arroz branco pré-cozido e cozido, sem adição de sal",
          "es": "Arroz blanco precocido y cocido, sin sal añadida",
          "en": "White precooked rice, cooked, no added salt",
        },
      ),
      "food:b21de32a12d0072a7e865109f2e559234ceadfd5975d4555daa33dd7636ea99d": (
        version:
            "c57cf7461ca1dffc7b240739bd95944cc9bac2428df0d8aca9b0e5de14dde889",
        original: "Riz blanc, cru",
        names: {
          "pt": "Arroz branco cru",
          "es": "Arroz blanco crudo",
          "en": "White rice, raw",
        },
      ),
      "food:023323e2410298daa6dfddda7d05c7d31451f08d559b3f59332352b3fea511f3": (
        version:
            "a01710b84f865e4a067f436a32f4d427f126690db6c77ed87b24b2548ec4efa5",
        original: "Haricot rouge, sec",
        names: {
          "pt": "Feijão-vermelho seco",
          "es": "Alubias rojas secas",
          "en": "Red kidney beans, dried",
        },
      ),
      "food:2fd3fbc8eb520c05499a5e8030a138fc342b1f1ebbbf2bb857aa00a3376a6fa4": (
        version:
            "d5a1a4872551f4f5b173edd65dd148b8e45ccd4044f6359b3ffc63db1bb8ed59",
        original: "Haricot rouge, bouilli/cuit à l'eau",
        names: {
          "pt": "Feijão-vermelho cozido em água",
          "es": "Alubias rojas hervidas en agua",
          "en": "Red kidney beans, boiled in water",
        },
      ),
      "food:577a347aae6b513152b2bf53d75db2ce0c5635ea6632cf8405afcaa4097d493f": (
        version:
            "6a94d5c04886f91d4bcb7bb2cea9ec92ced68dcab0f64bb6af5b3d8b40fea297",
        original: "Haricot rouge, appertisé, égoutté",
        names: {
          "pt": "Feijão-vermelho em conserva, escorrido",
          "es": "Alubias rojas en conserva, escurridas",
          "en": "Red kidney beans, canned, drained",
        },
      ),
      "food:0997f015880a7e1d6a0ec156859b9f8feae66550f17e025d93abbbb118c8441f": (
        version:
            "70a92633a6ef614ed7c2c653302538cf630fb2cf55d7c39fe505e2f975dd5749",
        original: "Haricot blanc, bouilli/cuit à l'eau",
        names: {
          "pt": "Feijão-branco cozido em água",
          "es": "Alubias blancas hervidas en agua",
          "en": "White beans, boiled in water",
        },
      ),
      "food:7d7ac0f2c607eeb480fbf3ff6885174f73028204a76ed0740020c8c12ff3becf": (
        version:
            "7526c1fa9a17e7ac1989d82379a2b840b351f4038deb01469e4d8e567f130b1b",
        original: "Haricot blanc, sec",
        names: {
          "pt": "Feijão-branco seco",
          "es": "Alubias blancas secas",
          "en": "White beans, dried",
        },
      ),
      "food:dccfc401e36f96bce616cadf1772a0f43accd61cb0384e46dee0712845c996f5": (
        version:
            "479efcb96f3d8d0245b03fad0fac9461f7759bebf70f4a80ca3f1474f01a4026",
        original: "Haricot blanc, appertisé, égoutté",
        names: {
          "pt": "Feijão-branco em conserva, escorrido",
          "es": "Alubias blancas en conserva, escurridas",
          "en": "White beans, canned, drained",
        },
      ),
    };
