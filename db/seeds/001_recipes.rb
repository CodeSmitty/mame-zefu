exit unless Rails.env.development?

recipes_data = [
  {
    name: 'Crispy Balsamic Chicken Thighs',
    ingredients: "1/2 cup balsamic vinegar\n4 tablespoons honey\n2 tablespoons low-sodium soy sauce\n6 cloves garlic, peeled and minced\n2 tablespoons canola oil\n2 pounds boneless skinless chicken thighs\n1/2 teaspoon kosher or sea salt\n1/2 teaspoon ground black pepper",
    directions: "1. Preheat the oven to 375°F.\n\n2. In a small bowl, whisk together the balsamic vinegar, honey, soy sauce, and garlic until combined.\n\n3. Heat the canola oil in an oven-safe skillet to medium-high. Season the chicken thighs with the salt and black pepper. Once the pan is hot, place the chicken thighs into the pan and sear until crispy, about 5 minutes. Turn the chicken over and cook another 2 to 3 minutes. Add the sauce to the pan and bring to a simmer. Transfer to the oven and roast for 10 minutes, until the internal temperature reaches 165°F.\n\n4. Serve immediately or place in microwaveable airtight containers and refrigerate for up to 5 days. To reheat, microwave on high for 1 to 2 minutes, until heated through.",
    yield: 'Serves 6',
    prep_time: '10 mins',
    cook_time: '20 mins',
    rating: 3,
    is_favorite: false,
    description: 'A delightfully tangy and sweet sauce makes the perfect finish for seared chicken thighs. Serve with vegetables, soup, or a grain side dish for a family favorite weeknight meal that is ready in less than 30 minutes.',
    notes: "When searing meat, leave it untouched in a medium-high skillet until the bottom is lightly browned and crispy. If you turn or move the meat too frequently, the brown crust will not form.\n\nInstead of the chicken thighs, try lean 4-ounce steaks."
  },
  {
    name: 'Best Ever Potato Soup',
    ingredients: "6 bacon strips, diced\n3 cups cubed peeled potatoes\n1 small carrot, grated\n1/2 cup chopped onion\n1 tablespoon dried parsley flakes\n1/2 teaspoon salt\n1/2 teaspoon pepper\n1/2 teaspoon celery seed\n1 can (14-1/2 ounces) chicken broth\n3 tablespoons all-purpose flour\n3 cups 2% milk\n8 ounces Velveeta, cubed\n2 green onions, thinly sliced, optional",
    directions: "1. In a large saucepan, cook bacon over medium heat until crisp, stirring occasionally; drain drippings. Add vegetables, seasonings and broth; bring to a boil. Reduce heat; simmer, covered, until potatoes are tender, 10-15 minutes.\n\n2. Mix flour and milk until smooth; stir into soup. Bring to a boil, stirring constantly; cook and stir until thickened, about 2 minutes. Stir in cheese until melted. If desired, serve with green onions.",
    yield: '8 servings (2 quarts).',
    prep_time: '10 mins',
    cook_time: '20 mins',
    rating: nil,
    is_favorite: true,
    description: '',
    notes: "If you prefer a thicker soup, you can add an additional tablespoon of flour, or substitute some of the 2% milk for whole or heavy cream.\n\nIf you don’t have Velveeta, cheddar or Colby jack are good substitutes."
  },
  {
    name: 'Best Banana Bread',
    ingredients: "1/2 cup butter, softened\n1 cup granulated sugar\n2 eggs, beaten\n3 bananas, finely crushed (for serious and extreme moist and delicious, try 4 bananas)\n1 1/2 cups all-purpose flour\n1 teaspoon baking soda\n1/2 teaspoon salt\n1/2 teaspoon vanilla (optional)",
    directions: "1. Remove odd pots and pans from oven.\n\n2. Preheat oven to 350º / 180º.\n\n3. Cream together butter and sugar.\n\n4. Add eggs and crushed bananas.\n\n5. Combine well.\n\n6. Sift together flour, soda and salt. Add to creamed mixture. Add vanilla.\n\n7. Mix just until combined. Do not overmix.\n\n8. Pour into greased and floured loaf pan.\n\n9. Bake at 350º / 180º for 55 minutes.\n\n10. Keeps well, refrigerated.",
    yield: '1 loaf, 10 serving(s)',
    prep_time: '10 mins',
    cook_time: '1 hour ',
    rating: 3,
    is_favorite: false,
    description: '',
    notes: ''
  },
  {
    name: 'Curried Apricot Couscous',
    ingredients: "1/3 cup chopped onion\n3 tablespoons butter\n1-1/2 cups chicken broth\n1 cup chopped dried apricots\n1/4 teaspoon curry powder\n1 cup uncooked couscous",
    directions: "1. In a small saucepan, saute onion in butter. Stir in the broth, apricots and curry powder. Bring to a boil. Stir in couscous.\n\n2. Cover and remove from the heat; let stand for 5-10 minutes or until liquid is absorbed. Fluff with a fork.",
    yield: '5 servings.',
    prep_time: '10 mins',
    cook_time: '10 mins',
    rating: 5,
    is_favorite: true,
    description: '',
    notes: ''
  },
  {
    name: 'Garlic Beef Enchiladas',
    ingredients: "1 pound ground beef\n1 medium onion, chopped\n2 tablespoons all-purpose flour\n1 tablespoon chili powder\n1 teaspoon salt\n1 teaspoon garlic powder\n1/2 teaspoon ground cumin\n1/4 teaspoon rubbed sage\n1 can (14-1/2 ounces) stewed tomatoes, cut up\n\nSAUCE:\n1/3 cup butter\n4 to 6 garlic cloves, minced\n1/2 cup all-purpose flour\n1 can (14-1/2 ounces) beef broth\n1 can (15 ounces) tomato sauce\n1 to 2 tablespoons chili powder\n1 to 2 teaspoons ground cumin\n1 to 2 teaspoons rubbed sage\n1/2 teaspoon salt\n10 flour tortillas (6 inches), warmed\n2 cups shredded Colby-Monterey Jack cheese, divided",
    directions: "1. Preheat oven to 350°. In a large skillet, cook beef and onion over medium heat until beef is no longer pink, 6-8 minutes, breaking meat into crumbles; drain. Stir in flour and seasonings. Add tomatoes; bring to a boil. Reduce heat; simmer, covered, 15 minutes.\n\n2. In a saucepan, heat butter over medium-high heat. Add garlic; cook and stir 1 minute or until tender. Stir in flour until blended; gradually whisk in broth. Bring to a boil; cook and stir until thickened, about 2 minutes. Stir in tomato sauce and seasonings; heat through.\n\n3. Pour 1-1/2 cups sauce into an ungreased 13x9-in. baking dish. Place about 1/4 cup beef mixture off-center on each tortilla; top with 1-2 tablespoons cheese. Roll up and place over sauce, seam side down. Top with remaining sauce.\n\n4. Bake, covered, until heated through, 30-35 minutes. Sprinkle with remaining cheese. Bake, uncovered, until cheese is melted, 10-15 minutes longer. Serve with toppings as desired.",
    yield: '5 servings.',
    prep_time: '30 mins',
    cook_time: '40 mins',
    rating: 5,
    is_favorite: true,
    description: '',
    notes: ''
  },
  {
    name: 'Lemony Green Beans with Almonds',
    ingredients: "1 pound green beans, trimmed\n2 tablespoons olive oil\nJuice and zest of 1 lemon, divided\n⅛ teaspoon kosher or sea salt\n¼ teaspoon ground black pepper\n¼ cup freshly grated Parmesan cheese\n¼ cup sliced almonds",
    directions: "1. Bring a large pot of water to a boil.\nAdd the green beans and cook for 2 to 3 minutes. Transfer to a bowl with ice water for 2 to 3 minutes. Drain.\n\n2. Heat olive oil in a large skillet over medium heat. Add the green beans and sauté for 4 to 5 minutes, until lightly browned. Add the lemon juice and simmer for 1 to 2 minutes, then season with the salt and black pepper.\n\n3. Transfer to a serving dish and top with the lemon zest, Parmesan cheese, and almonds.\n\n4. For leftovers, store in microwaveable airtight containers for up to 5 days.\nReheat in the microwave on high for 1 to 2 minutes, until heated through.",
    yield: 'Serves 4',
    prep_time: '15 mins',
    cook_time: '15 mins',
    rating: 4,
    is_favorite: true,
    description: 'Green beans are packed with vitamins and minerals, and are low in calories. This recipe dresses them up with olive oil, lemon, Parmesan cheese, and almonds for a delicious side dish.',
    notes: "Blanch and shock the green beans, boiling them for a few minutes then transferring them immediately to ice water. This helps keep the green beans crips and preserves their bright green color.\n\nTry broccoli instead of green beans."
  },
  {
    name: 'Italian-Style Turkey Meat Loaf',
    ingredients: "2 pounds ground turkey\n1 yellow onion, peeled and finely minced\n8 garlic cloves, peeled and minced\n4 large eggs\n2 cups panko bread crumbs\n1 cup fresh flat-leaf Italian parsley, chopped\n2 tablespoon Dijon mustard\n2 tablespoon Italian seasoning\n1½ teaspoon kosher or sea salt\n1 teaspoon ground black pepper\n1 cup shredded mozzarella cheese\n1 cup lower-sodium marinara sauce",
    directions: "1. Preheat the oven to 375°F. Coat a loaf pan with cooking spray.\n\n2. In a large bowl, mix together the turkey, onion, garlic, eggs, bread crumbs, parsley, Dijon mustard, Italian seasoning, salt, and black pepper until thoroughly combined.\n\n3. Transfer the mixture to the loaf pan.\nSprinkle the mozzarella cheese and spread the marinara sauce on top. Bake for 45 to 50 minutes, until the internal temperature reaches 165°F.",
    yield: 'Serves 8',
    prep_time: '15 mins',
    cook_time: '50 mins',
    rating: 5,
    is_favorite: true,
    description: 'Good old meat loaf gets a flavor upgrade in this recipe by incorporating Italian seasoning, mozzarella cheese, and marinara sauce. Although turkey is a lean meat, this meat loaf is tender and juicy because it contains ingredients like Dijon mustard that provide moisture and flavor.',
    notes: "Make mini meat loaves by spooning the mixture into greased muffin tin wells. Bake for 15 to 25 minutes, until cooked through.\n\nTry lean ground beef, pork, or chicken."
  },
  {
    name: 'Fettuccine Alfredo',
    ingredients: "8 ounces uncooked fettuccine\n6 tablespoons butter, cubed\n2 cups heavy whipping cream\n3/4 cup grated Parmesan cheese, divided\n1/2 cup grated Romano cheese\n2 large egg yolks, lightly beaten\n1/4 teaspoon salt\n1/8 teaspoon pepper\n1/8 teaspoon ground nutmeg",
    directions: "1. Cook fettuccine according to package directions. Meanwhile, in a saucepan, melt butter over medium-low heat. Stir in cream, 1/2 cup Parmesan cheese, Romano cheese, egg yolks, salt, pepper and nutmeg. Cook and stir over medium-low heat until a thermometer reads 160° (do not boil).\n\n2. Drain fettuccine; serve with Alfredo sauce and remaining 1/4 cup Parmesan cheese.",
    yield: '4 servings.',
    prep_time: '10 mins',
    cook_time: '10 mins',
    rating: 4,
    is_favorite: true,
    description: '',
    notes: ''
  },
  {
    name: 'Roasted Red Pepper & Pesto Omelet',
    ingredients: "8 large eggs\n¼ cup Basil Pesto\n¼ teaspoon ground black pepper\n⅛ teaspoon kosher or sea salt\nCooking spray\n½ cup baby spinach leaves\n½ cup jarred roasted red peppers, chopped\n¾ cup shredded white Cheddar cheese",
    directions: "1. Heat a large nonstick skillet over medium-low heat.\n\n2. In a medium bowl, whisk together the eggs, pesto, black pepper, and salt until thoroughly combined.\n\n3. Coat the skillet with the cooking spray.\nAdd ¼ of the spinach and stir until slightly wilted. Pour in ¼ of the egg mixture. Let cook for 2 to 3 minutes, until the egg is almost set. Place ¼ of the roasted red peppers and cheese in the center of the omelet. Fold the omelet in half. Place a lid on top and cook for 1 to 2 minutes, until the cheese is melted.\n\n4. Repeat step 3 with the remaining ingredients to make 4 omelets total.\n\n5. Store the omelets in microwaveable airtight containers and refrigerate for up to 5 days. Reheat by microwaving on high for 2 minutes, until heated through.",
    yield: 'Serves 4',
    prep_time: '10 mins',
    cook_time: '20 mins',
    rating: 4,
    is_favorite: false,
    description: 'You can put almost any vegetable in an omelet, and this variation takes the traditional omelet to the next level with roasted red peppers and pesto. Make the pesto at home with fresh basil and spinach so you can instantly add flavor to many dishes with one sauce.',
    notes: 'Replace roasted red peppers with kalamata olives or artichokes.'
  },
  {
    name: 'Rosemary-Apricot Pork Tenderloin',
    ingredients: "3 tablespoons minced fresh rosemary\n3 tablespoons olive oil, divided\n4 garlic cloves, minced\n1 teaspoon salt\n1/2 teaspoon pepper\n2 pork tenderloins (1 pound each)\n\nGLAZE:\n1 cup apricot preserves\n3 tablespoons lemon juice\n2 garlic cloves, minced",
    directions: "1. In a small bowl, combine the rosemary, 1 tablespoon oil, garlic, salt and pepper; brush over pork.\n\n2. In a large cast-iron or other ovenproof skillet, brown pork in remaining oil on all sides. Bake at 425° for 15 minutes.\n\n3. In a small bowl, combine the glaze ingredients; brush over pork. Bake until a thermometer reads 145°, 10-15 minutes longer, basting occasionally with pan juices. Let stand 5 minutes before slicing.",
    yield: '8 servings.',
    prep_time: '15 mins',
    cook_time: '25 mins',
    rating: 5,
    is_favorite: true,
    description: '',
    notes: ''
  },
  {
    name: 'Maple Mustard Brussels Sprouts with Toasted Walnuts',
    ingredients: "¼ cup chopped walnuts\n2 tablespoons olive oil\n2 pounds Brussels sprouts, trimmed and halved\n¼ teaspoon kosher or sea salt\n¼ teaspoon ground black pepper\n⅛ teaspoon crushed red pepper flakes\n2 tablespoons Dijon mustard\n1 tablespoon pure maple syrup",
    directions: "1. Heat a dry skillet over medium heat.\nAdd the walnuts and toast, stirring occasionally, for about 1 to 2 minutes, until lightly toasted. Transfer to a small bowl.\n\n2. Heat the olive oil in the same skillet over medium heat. Add the Brussels sprouts and sauté, stirring occasionally, for 8 to 10 minutes, until slightly fork tender and browned on the outside. Season with the salt, black pepper, and crushed red pepper flakes.\n\n3. In a small bowl, whisk together the Dijon mustard and maple syrup. Pour the mixture into the pan and stir to combine, bringing to a light simmer.\n\n4. Transfer the mixture to the dishes and top with the toasted walnuts.\n\n5. For leftovers, keep the walnuts separate in a small sealed plastic bag and put the Brussels sprouts in microwaveable airtight containers in the refrigerator for up to 3 to 4 days.\nReheat in the microwave on high for 1 to 2 minutes, until heated through.",
    yield: 'Serves 6',
    prep_time: '15 mins',
    cook_time: '15 mins',
    rating: 4,
    is_favorite: false,
    description: 'Brussels sprouts, a cruciferous vegetable, are a great source of vitamin K, vitamin C, vitamin B6, potassium, and fiber. When sauteed in a hot skillet, they become crispy on the outside and fork tender. The maple mustard sauce and crunchy walnuts take this dish to the next level.',
    notes: "Try honey instead of maple syrup.\n\nTry broccoli instead of Brussels sprouts."
  },
  {
    name: 'Stir-Fry Sauce',
    ingredients: "½ cup unsalted vegetable, chicken, or beef stock\n3 tablespoons low-sodium soy sauce\n1 tablespoon honey\n2 teaspoons sesame oil\n1 teaspoon sriracha\n4 garlic cloves, peeled and minced\n1 inch piece fresh ginger, peeled and minced\n1 tablespoon cornstarch",
    directions: 'In a bowl, whisk the ingredients together until combined. Store in an airtight container in the refrigerator for up to 5 days.',
    yield: 'Makes 1 Cup',
    prep_time: '20 mins',
    cook_time: '',
    rating: 4,
    is_favorite: false,
    description: "Stir-fry sauce can be whipped up in a matter of minutes and stored in the fridge to be used all week. It's perfectly balance, with savory, sweet, umami, and spicy notes.",
    notes: ''
  },
  {
    name: 'Tofu & Green Bean Stir-Fry',
    ingredients: "1 (14-ounce) package extra-firm tofu\n2 tablespoons canola oil\n1 pound green beans, chopped\n2 carrots, peeled and thinly sliced\n½ cup Stir-Fry Sauce\n2 cups Rice",
    directions: "1. Remove the tofu from the package and place it on a plate lined with a kitchen towel. Place another kitchen towel on top of the tofu and place a heavy pot on top, changing towels if they become soaked. Let sit for 15 minutes to remove the moisture. Cut the tofu into 1-inch cubes.\n\n2. Heat the canola oil in a large wok or skillet to medium-high heat. Add the tofu cubes and cook, flipping every 1 to 2 minutes so all sides become browned. Remove from the skillet and place the green beans and carrots in the hot oil. Stir-fry for 4 to 5 minutes, tossing occasionally, until crisp and slightly tender.\n\n3. While the vegetables are cooking, prepare the Stir-Fry Sauce\n\n4. Place the tofu back in the skillet. Pour the sauce over the tofu and vegetables and let simmer for 2 to 3 minutes.\n\n5. Serve the stir-fry over rice",
    yield: 'Serves 4',
    prep_time: '20 mins',
    cook_time: '20 mins',
    rating: 5,
    is_favorite: true,
    description: 'Stir-fried dishes are perfect for weeknights because the cooking process is quick, especially if the sauce is made in advance.',
    notes: 'Try seitan instead of tofu. It also is a great source of protein and lends itself well to Asian-style dishes.'
  },
  {
    name: 'Vegetarian Linguine',
    ingredients: "1 pound uncooked linguine\n2 tablespoons butter\n1 tablespoon olive oil\n2 shallot, minced\n8 garlic cloves, minced\n1 pound fresh mushrooms, sliced\n3 medium tomatoes, diced\n3 medium zucchini, halved and sliced\n1 tablespoon italian seasoning\n¼  teaspoon red pepper flakes\n1 cup shredded smoked cheese\n½ cup heavy whipping cream",
    directions: "Cook linguine according to package directions.\n\nMeanwhile, in a large skillet, heat butter and oil over medium heat. Add garlic and shallot, saute.\n\nAdd mushrooms; saute until softened and reduced liquid.\n\nAdd tomato, zucchini and seasonings. Reduce heat; simmer, covered.\n\nStir in cheese until melted. Stir in cream.\n\nDrain linguine; add to vegetable mixture. Toss to coat.",
    yield: '6 servings.',
    prep_time: '15 mins',
    cook_time: '15 mins',
    rating: 4,
    is_favorite: true,
    description: '',
    notes: ''
  },
  {
    name: 'Grilled Pork & Pineapple Kebabs',
    ingredients: "2 pounds pork tenderloin, cubed\n1 small pineapple, peeled, cored, and cubed (about 3 cups)\n2 red bell peppers, seeded and cut into 2-inch pieces\n1 red onion, peeled and cut into 2-inch pieces\n¾ teaspoon kosher or sea salt, divided\n½ teaspoon ground black pepper, divided\n1½ tablespoons canola oil\n1 tablespoon honey\n½ tablespoon low-sodium soy sauce\n½ tablespoon apple cider vinegar\n½ tablespoons ground cumin",
    directions: "1. Preheat the grill over medium heat.\nWhile the grill is warming up, thread the cubed pork, pineapple, bell peppers, and red onion on skewers, alternating between each ingredient. Season the kebabs with half of the salt and half of\nthe black pepper.\n\n2. In a small bowl, whisk together the canola oil, honey, soy sauce, apple cider\nvinegar, and cumin and the remaining salt and black pepper. Brush half of the marinade onto the kebabs.\n\n3. Grill for 3 to 4 minutes per side, until the pork reaches 145°F and the vegetables are tender. Each time you flip the kebabs, brush with additional marinade.",
    yield: 'Serves 6',
    prep_time: '20 mins',
    cook_time: '20 mins',
    rating: 3,
    is_favorite: false,
    description: "Kebabs are a quintessential summer recipe, and our version got a sweet upgrade with fresh pineapple, red bell pepper, and a mixture of honey, soy sauce, and apple cider vinegar. If you have a bit of extra time, you could marinate the kebabs first, but it's equally delicious brushed on while grilling.",
    notes: "If using wooden skewers, soak them in water for 30 minutes before threading to avoid them charring or catching on fire.\n\nTry using steak instead of  pork and mango instead of pineapple."
  },
]

recipes_data.each do |recipe_data|
  Recipe.find_or_initialize_by(name: recipe_data[:name]).update(recipe_data)
end

puts "Seed data for recipes created successfully!"