# Treino do modelo de foto de alimentos

Scripts que geraram `assets/models/food_photo_int8.tflite` (22–23/11/2026). Rodam fora do app, num venv com PyTorch/timm/transformers e GPU. Dados e pesos ficavam em `.local/fotos-alimentos/`, nunca no repositório; em 23/11 foram apagados a pedido do autor e só o essencial ficou em `.local/fotos-alimentos-preservado/` (manifestos, modelos, métricas e logs). Para retreinar, baixar de novo pelos scripts e recriar o venv. Decisões, números e limites: `docs/planejamento/pesquisa-registro-voz-e-foto.md`.

Ordem:

1. Dados: `n5k_download.py`, `oi_select.py` + `oi_download.py` (classes em `oi_food_classes.csv`), `commons_download.py`. Cada base grava `manifest.json` com autor, licença e SHA-256.
2. Professor: `teacher_label.py classes_final.json <fotos> <saida>` (SigLIP 2 com recortes, marcações `*_grid`). Professor ajustado (23/11): `teacher_embed.py` por base em `emb/<base>`, `teacher_probe.py` (marcações `*_probe`) e `teacher_ensemble.py` (média, `*_ens`, e a lista `br_holdout.json`).
3. Aluno: `TEACHER=ens train_student.py classes_final.json .local/fotos-alimentos <saida> tf_efficientnet_lite0.in1k 20`.
4. Exportação e medida: `export_student.py` (ONNX → TFLite int8); `eval_n5k.py` mede contra o Nutrition5k.
5. App: copiar o `.tflite` int8 e regenerar `assets/models/food_photo_classes.json` a partir de `classes_final.json` (mesma ordem das classes).

`classes_final.json` liga cada uma das 370 classes a `food_id`/`version_id` do catálogo.
