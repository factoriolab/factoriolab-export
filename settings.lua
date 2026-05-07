data:extend(
  {
    {
      type = "bool-setting",
      name = "factoriolab-export-enabled",
      order = "a",
      setting_type = "runtime-global",
      default_value = true
    },
    {
      type = "int-setting",
      name = "factoriolab-export-entries-per-tick",
      order = "b",
      setting_type = "runtime-global",
      default_value = 200,
      minimum_value = 1
    }
  }
)
