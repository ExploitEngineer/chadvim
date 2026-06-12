-- add typr plugin to get monkeytype experience, but in neovim btw
return {
  "nvzone/typr",
  dependencies = "nvzone/volt",
  opts = {},
  cmd = { "Typr", "TyprStats" },
}
