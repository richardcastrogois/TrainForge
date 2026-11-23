def build(classes):
    # ingrediente do Nutrition5k -> classe, por nome em inglês exato da classe
    en2slug = {}
    for c in classes:
        for alias in [c["en"]] + [a.strip() for a in c["en"].split(",")]:
            en2slug.setdefault(alias.lower(), c["slug"])
    manual = {"white rice": "arroz_branco", "brown rice": "arroz_integral", "rice": "arroz_branco", "chicken": "frango_grelhado",
              "chicken breast": "frango_grelhado", "steak": "bife", "beef": "bife", "pork": "lombo", "salmon": "salmao",
              "potatoes": "batata_cozida", "sweet potato": "batata_doce", "carrots": "cenoura", "carrot": "cenoura", "eggs": "ovo_cozido",
              "scrambled eggs": "ovo_mexido", "lettuce": "alface", "spinach": "espinafre", "cucumbers": "pepino", "tomatoes": "tomate",
              "cherry tomatoes": "tomate", "apple": "maca", "pasta": "macarrao", "bread": "pao_forma", "pizza": "pizza",
              "broccoli": "brocolis", "cauliflower": "couve_flor", "corn": "milho_verde", "green beans": "vagem", "zucchini": "abobrinha",
              "mushroom": "cogumelo", "mushrooms": "cogumelo", "watermelon": "melancia", "cantaloupe": "melao", "honeydew melon": "melao",
              "pineapple": "abacaxi", "grapes": "uva", "blueberries": "mirtilo", "raspberries": "framboesa", "blackberries": "amora",
              "strawberries": "morango", "bacon": "bacon", "sausage": "linguica", "avocado": "abacate", "guacamole": "guacamole",
              "beans": "feijao_preto", "black beans": "feijao_preto", "pinto beans": "feijao_carioca", "chickpeas": "grao_de_bico",
              "hummus": "homus", "olives": "azeitona", "cabbage": "repolho", "red cabbage": "repolho_roxo", "bell peppers": "pimentao",
              "asparagus": "aspargo", "brussels sprouts": "couve_bruxelas", "beets": "beterraba", "quinoa": "quinoa", "lentils": "lentilha",
              "tofu": "tofu", "fish": "peixe_grelhado", "cod": "peixe_assado", "shrimp": "camarao", "bok choy": "acelga", "kale": "couve",
              "arugula": "rucula", "celery": "aipo", "onions": "cebola", "orange": "laranja", "banana": "banana", "pear": "pera",
              "yogurt": "iogurte", "cottage cheese": "ricota", "mozzarella cheese": "mussarela", "parmesan cheese": "parmesao",
              "garden salad": "salada_verde", "mixed greens": "salada_verde", "caesar salad": "salada_caesar", "french fries": "batata_frita",
              "mashed potatoes": "pure_batata", "turkey": "peru", "ham": "presunto", "meatballs": "almondega", "eggplant": "berinjela",
              "pork chop": "bisteca", "brownie": "brownie", "cookie": "cookie", "cake": "bolo_simples", "pie": "torta_doce", "jalapenos": "pimenta"}
    for k, v in manual.items():
        en2slug[k] = v
    return en2slug
