# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "lodash/", to: "https://cdn.skypack.dev/lodash-es/"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "tom-select", to: "https://cdnjs.cloudflare.com/ajax/libs/tom-select/2.3.1/esm/tom-select.complete.min.js"
pin "flowbite", to: "https://cdnjs.cloudflare.com/ajax/libs/flowbite/2.2.1/flowbite.turbo.min.js"
