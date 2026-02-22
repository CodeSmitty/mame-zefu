const DRAFT_STORAGE_PREFIX = "recipe_draft:storage:"
const MAINTENANCE_KEY = "recipe_draft:maintenance"
const TEST_KEY = "recipe_draft:test"

const MAINTENANCE_INTERVAL_MS = 24 * 60 * 60 * 1000 // 24 hours
const DRAFT_MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000 // 30 days

export function storageAvailable() {
  try {
    localStorage.setItem(TEST_KEY, TEST_KEY)
    localStorage.removeItem(TEST_KEY)
    return true
  } catch {
    return false
  }
}

export function hasRecipeDraft(recipeKey) {
  const recipeDraft = readRecipeDraft(recipeKey)
  if (Object.keys(recipeDraft).length === 0) return false

  return true
}

export function readRecipeDraft(recipeKey) {
  const storageKey = recipeStorageKey(recipeKey)
  const recipeDraft = loadRecipeDraft(storageKey)
  if (!recipeDraft) return {}

  if (!isValidRecipeDraft(recipeDraft)) {
    removeRecipeDraft(recipeKey)
    return {}
  }

  return recipeDraft.fields
}

export function writeRecipeDraft(recipeKey, fields) {
  localStorage.setItem(
    recipeStorageKey(recipeKey),
    JSON.stringify({
      updatedAt: Date.now(),
      fields,
    }),
  )
}

export function removeRecipeDraft(recipeKey) {
  const storageKey = recipeStorageKey(recipeKey)
  localStorage.removeItem(storageKey)
}

function recipeStorageKey(recipeKey) {
  return `${DRAFT_STORAGE_PREFIX}${recipeKey}`
}

function loadRecipeDraft(storageKey) {
  const rawValue = localStorage.getItem(storageKey)
  if (!rawValue) return null

  try {
    return JSON.parse(rawValue)
  } catch {
    localStorage.removeItem(storageKey)
    return null
  }
}

function isValidRecipeDraft(recipeDraft) {
  return (
    recipeDraft &&
    typeof recipeDraft === "object" &&
    recipeDraft.fields &&
    typeof recipeDraft.fields === "object" &&
    "updatedAt" in recipeDraft &&
    isActiveRecipeDraft(recipeDraft)
  )
}

function isActiveRecipeDraft(recipeDraft) {
  const updatedAt = Number(recipeDraft.updatedAt)
  if (!Number.isFinite(updatedAt)) return false

  return Date.now() - updatedAt <= DRAFT_MAX_AGE_MS
}

export function runRecipeDraftMaintenance() {
  if (!shouldRunMaintenance()) return

  draftStorageKeys().forEach((storageKey) => {
    const recipeDraft = loadRecipeDraft(storageKey)
    if (isValidRecipeDraft(recipeDraft)) return

    localStorage.removeItem(storageKey)
  })

  localStorage.setItem(MAINTENANCE_KEY, String(Date.now()))
}

function draftStorageKeys() {
  const keys = []
  for (let i = 0; i < localStorage.length; i++) {
    const storageKey = localStorage.key(i)
    if (storageKey !== null && storageKey.startsWith(DRAFT_STORAGE_PREFIX)) {
      keys.push(storageKey)
    }
  }
  return keys
}

function shouldRunMaintenance() {
  const lastRunAt = Number(localStorage.getItem(MAINTENANCE_KEY))

  // if not set or invalid, maintenance should be run
  if (!Number.isFinite(lastRunAt)) return true

  return Date.now() - lastRunAt > MAINTENANCE_INTERVAL_MS
}
