exit unless Rails.env.development?

recipes_data = [
  {
    name: "Spaghetti Bolognese",
    yield: "4 servings",
    ingredients: "Ground beef,\nOnion,\nGarlic,\nTomato sauce,\nSpaghetti,\nOlive oil",
    directions: "1. Cook spaghetti according to package instructions.\n2. Brown ground beef with onion and garlic.\n3. Add tomato sauce and simmer.\n4. Serve sauce over cooked spaghetti.",
    prep_time: 15,
    cook_time: 30,
    description: "Classic Italian dish with savory meat sauce over spaghetti.",
    notes: "You can add Parmesan cheese on top for extra flavor.",
    rating: 4.5,
    is_favorite: true,
    category_names: %w[Main Pasta Fruit]
  },
  {
    name: "Chicken Stir-Fry",
    yield: "3 servings",
    ingredients: "Chicken breast,\nBroccoli,\nBell pepper,\nSoy sauce,\nGinger,\nGarlic,\nSesame oil",
    directions: "1. Stir-fry chicken until cooked.\n2. Add vegetables and stir-fry.\n3. Mix soy sauce, ginger, and garlic.\n4. Pour sauce over stir-fry and toss.\n5. Drizzle with sesame oil.",
    prep_time: 20,
    cook_time: 15,
    description: "Quick and healthy chicken stir-fry with colorful vegetables.",
    notes: "Feel free to customize with your favorite veggies.",
    rating: 4.0,
    is_favorite: false,
    category_names: %w[Poultry Main]
  },
  {
    name: "Vegetarian Pizza",
    yield: "2 servings",
    ingredients: "Pizza dough,\nTomato sauce,\nMozzarella cheese,\nBell peppers,\nMushrooms,\nOlives",
    directions: "1. Roll out pizza dough.\n2. Spread tomato sauce over the dough.\n3. Add toppings and cheese.\n4. Bake in preheated oven until crust is golden.",
    prep_time: 25,
    cook_time: 20,
    description: "Delicious vegetarian pizza with a crispy crust and fresh toppings.",
    notes: "Experiment with different vegetable combinations.",
    rating: 4.2,
    is_favorite: true,
    category_names: %w[Vegetable Main]
  },
  {
    name: "Beef Tacos",
    yield: "5 servings",
    ingredients: "Ground beef,\nTaco seasoning,\nTortillas,\nLettuce,\nTomato,\nCheese,\nSour cream",
    directions: "1. Brown ground beef and add taco seasoning.\n2. Warm tortillas.\n3. Assemble tacos with beef, lettuce, tomato, cheese, and sour cream.",
    prep_time: 15,
    cook_time: 20,
    description: "Classic beef tacos with seasoned meat and fresh toppings.",
    notes: "Add your favorite salsa for extra flavor.",
    rating: 4.3,
    is_favorite: true,
    category_names: %w[Beef Main]
  },
  {
    name: "Pasta Primavera",
    yield: "3 servings",
    ingredients: "Penne pasta,\nBroccoli,\nCarrots,\nBell peppers,\nCherry tomatoes,\nAlfredo sauce",
    directions: "1. Cook pasta according to package instructions.\n2. Steam broccoli and carrots.\n3. Saute bell peppers and cherry tomatoes.\n4. Mix with cooked pasta and Alfredo sauce.",
    prep_time: 20,
    cook_time: 15,
    description: "Vegetarian pasta dish with colorful vegetables in a creamy Alfredo sauce.",
    notes: "Use whole wheat pasta for a healthier option.",
    rating: 4.1,
    is_favorite: false,
    category_names: %w[Pasta Main]
  },
  {
    name: "Grilled Salmon",
    yield: "2 servings",
    ingredients: "Salmon fillets,\nLemon,\nOlive oil,\nGarlic,\nDill,\nSalt,\nPepper",
    directions: "1. Marinate salmon in olive oil, lemon juice, garlic, dill, salt, and pepper.\n2. Grill until salmon is cooked through.\n3. Serve with lemon wedges.",
    prep_time: 10,
    cook_time: 15,
    description: "Healthy and flavorful grilled salmon with a zesty lemon marinade.",
    notes: "Pair with a side of roasted vegetables.",
    rating: 4.4,
    is_favorite: true,
    category_names: %w[Seafood Main]
  },
  {
    name: "Mushroom Risotto",
    yield: "4 servings",
    ingredients: "Arborio rice,\nMushrooms,\nOnion,\nWhite wine,\nChicken broth,\nParmesan cheese,\nButter",
    directions: "1. Saute mushrooms and onion.\n2. Add Arborio rice and cook until translucent.\n3. Deglaze with white wine.\n4. Gradually add chicken broth and stir until creamy.\n5. Finish with Parmesan cheese and butter.",
    prep_time: 25,
    cook_time: 30,
    description: "Creamy and savory mushroom risotto with a touch of white wine.",
    notes: "Stir continuously for a perfect risotto consistency.",
    rating: 4.6,
    is_favorite: true,
    category_names: %w[Appetizer Main]
  },
  {
    name: "Homemade Lasagna",
    yield: "6 servings",
    ingredients: "Lasagna noodles,\nGround beef,\nOnion,\nGarlic,\nTomato sauce,\nRicotta cheese,\nMozzarella cheese",
    directions: "1. Cook lasagna noodles according to package instructions.\n2. Brown ground beef with onion and garlic.\n3. Layer noodles with meat sauce, ricotta, and mozzarella.\n4. Repeat layers and bake until bubbly.",
    prep_time: 30,
    cook_time: 45,
    description: "Classic homemade lasagna with layers of pasta, meat sauce, and cheesy goodness.",
    notes: "Let it rest for 10 minutes before serving for easier slicing.",
    rating: 4.7,
    is_favorite: true,
    category_names: %w[Pasta Main]
  },
  {
    name: "Shrimp Scampi",
    yield: "2 servings",
    ingredients: "Linguine,\nShrimp,\nGarlic,\nLemon juice,\nWhite wine,\nButter,\nParsley",
    directions: "1. Cook linguine according to package instructions.\n2. Saute shrimp with garlic in butter.\n3. Deglaze with white wine and add lemon juice.\n4. Toss with cooked linguine and garnish with parsley.",
    prep_time: 20,
    cook_time: 15,
    description: "Delicious shrimp scampi with a garlicky and lemony sauce.",
    notes: "Serve with a sprinkle of Parmesan cheese.",
    rating: 4.5,
    is_favorite: false,
    category_names: %w[Pasta Seafood Main]
  },
  {
    name: "Caprese Salad",
    yield: "2 servings",
    ingredients: "Tomatoes,\nFresh mozzarella,\nBasil leaves,\nBalsamic glaze,\nOlive oil,\nSalt,\nPepper",
    directions: "1. Slice tomatoes and fresh mozzarella.\n2. Arrange slices on a plate, alternating with basil leaves.\n3. Drizzle with balsamic glaze and olive oil.\n4. Season with salt and pepper.",
    prep_time: 10,
    cook_time: 0,
    description: "Refreshing Caprese salad with ripe tomatoes, mozzarella, and basil.",
    notes: "Use high-quality balsamic glaze for the best flavor.",
    rating: 4.4,
    is_favorite: true,
    category_names: %w[Salad Appetizer]
  },
  {
    name: "Vegetable Curry",
    yield: "4 servings",
    ingredients: "Mixed vegetables (e.g., carrots, peas, potatoes),\nCurry paste,\nCoconut milk,\nOnion,\nGarlic,\nGinger",
    directions: "1. Saute onion, garlic, and ginger in curry paste.\n2. Add mixed vegetables and saute until coated.\n3. Pour in coconut milk and simmer until vegetables are tender.",
    prep_time: 25,
    cook_time: 30,
    description: "Flavorful vegetable curry with a creamy coconut milk base.",
    notes: "Serve over rice or with naan bread.",
    rating: 4.2,
    is_favorite: false,
    category_names: %w[Vegetable Main]
  },
  {
    name: "Homemade Macaroni and Cheese",
    yield: "4 servings",
    ingredients: "Elbow macaroni,\nCheddar cheese,\nButter,\nFlour,\nMilk,\nMustard,\nSalt,\nPepper",
    directions: "1. Cook elbow macaroni according to package instructions.\n2. Make a roux with butter and flour.\n3. Gradually whisk in milk and bring to a simmer.\n4. Stir in shredded cheddar cheese until melted.\n5. Season with mustard, salt, and pepper.\n6. Mix with cooked macaroni.",
    prep_time: 20,
    cook_time: 25,
    description: "Classic macaroni and cheese made from scratch with a creamy cheese sauce.",
    notes: "Bake with breadcrumbs for a crunchy topping.",
    rating: 4.6,
    is_favorite: true,
    category_names: %w[Pasta Main]
  },
  {
    name: "Lemon Garlic Roast Chicken",
    yield: "4 servings",
    ingredients: "Whole chicken,\nLemon,\nGarlic,\nRosemary,\nThyme,\nOlive oil,\nSalt,\nPepper",
    directions: "1. Preheat oven to 375°F (190°C).\n2. Rub chicken with olive oil, salt, and pepper.\n3. Stuff cavity with lemon halves, garlic, rosemary, and thyme.\n4. Roast until internal temperature reaches 165°F (74°C).",
    prep_time: 15,
    cook_time: 90,
    description: "Juicy and flavorful roast chicken with a zesty lemon and garlic infusion.",
    notes: "Let the chicken rest before carving for best results.",
    rating: 4.7,
    is_favorite: true,
    category_names: %w[Poultry Main]
  },
  {
    name: "Quinoa Salad",
    yield: "3 servings",
    ingredients: "Quinoa,\nCucumber,\nCherry tomatoes,\nRed onion,\nFeta cheese,\nKalamata olives,\nOlive oil,\nLemon juice",
    directions: "1. Rinse quinoa and cook according to package instructions.\n2. Chop cucumber, cherry tomatoes, red onion, and olives.\n3. Mix quinoa with vegetables and crumbled feta cheese.\n4. Drizzle with olive oil and lemon juice.",
    prep_time: 15,
    cook_time: 20,
    description: "Healthy and refreshing quinoa salad with Mediterranean flavors.",
    notes: "Add grilled chicken for a protein boost.",
    rating: 4.2,
    is_favorite: false,
    category_names: %w[Salad Appetizer Side]
  },
]

recipes_data.each do |recipe_data|
  Recipe.find_or_initialize_by(name: recipe_data[:name]).update(recipe_data)
end

puts "Seed data for recipes created successfully!"