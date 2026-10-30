package nutrition

import "strings"

// Navigation vocabulary only. These terms do not assert food identity, translate
// preparation, change composition or replace reviewed per-version display names.
func foodSearchTerms(query, locale string) []string {
	q := strings.ToLower(strings.TrimSpace(query))
	var key string
	switch locale {
	case "pt-BR", "pt-PT":
		switch q {
		case "arroz":
			key = "rice"
		case "arroz branco":
			return []string{"rice, white", "riz blanc"}
		case "arroz integral":
			return []string{"rice, brown", "riz complet"}
		case "feijão vermelho", "feijao vermelho", "feijão-vermelho", "feijao-vermelho":
			return []string{"beans, red kidney", "haricot rouge"}
		case "feijão branco", "feijao branco", "feijão-branco", "feijao-branco":
			return []string{"beans, white", "haricot blanc"}
		case "feijao", "feijão", "feijoes", "feijões":
			key = "beans"
		case "leite":
			key = "milk"
		case "ovo", "ovos":
			key = "egg"
		case "frango":
			key = "chicken"
		case "banana":
			key = "banana"
		case "batata":
			key = "potato"
		}
	case "en":
		switch q {
		case "white rice":
			return []string{"rice, white", "riz blanc"}
		case "brown rice":
			return []string{"rice, brown", "riz complet"}
		case "red kidney beans":
			return []string{"beans, red kidney", "haricot rouge"}
		}
	case "es":
		switch q {
		case "arroz blanco":
			return []string{"rice, white", "riz blanc"}
		case "arroz integral":
			return []string{"rice, brown", "riz complet"}
		case "alubias rojas":
			return []string{"beans, red kidney", "haricot rouge"}
		case "arroz":
			key = "rice"
		case "frijol", "frijoles", "judías", "judias", "alubias":
			key = "beans"
		case "leche":
			key = "milk"
		case "huevo", "huevos":
			key = "egg"
		case "pollo":
			key = "chicken"
		case "plátano", "platano", "banana":
			key = "banana"
		case "patata", "papa":
			key = "potato"
		}
	}

	switch key {
	case "rice":
		return []string{"rice", "riz"}
	case "beans":
		return []string{"bean", "beans", "haricot", "haricots"}
	case "milk":
		return []string{"milk", "lait"}
	case "egg":
		return []string{"egg", "eggs", "oeuf", "oeufs", "œuf", "œufs"}
	case "chicken":
		return []string{"chicken", "poulet"}
	case "banana":
		return []string{"banana", "banane"}
	case "potato":
		return []string{"potato", "potatoes", "pomme de terre"}
	}
	return []string{}
}
