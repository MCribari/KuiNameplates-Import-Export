local LibSerialize = LibStub("LibSerialize")
local LibDeflate  = LibStub("LibDeflate")

-- Helpers
local function deepMerge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deepMerge(dst[k], v)
    else
      dst[k] = v
    end
  end
end

local function getProfileTable()
  if KuiNameplates and KuiNameplates.db and KuiNameplates.db.profile then
    return KuiNameplates.db.profile
  end
  KuiNameplatesDB = KuiNameplatesDB or {}
  KuiNameplatesDB.profile = KuiNameplatesDB.profile or {}
  return KuiNameplatesDB.profile
end

-- EXPORT
function KuiNameplates:ExportProfile()
  local t = getProfileTable()
  local ok, serialized = pcall(LibSerialize.Serialize, LibSerialize, t)
  if not ok then
    print("|cffff3333[KuiNameplates]|r Error serializing:", serialized)
    return
  end
  local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
  local encoded    = LibDeflate:EncodeForPrint(compressed)
  return encoded
end

-- IMPORT
function KuiNameplates:ImportProfileFromString(input, mode)
  if not input or input == "" then
    print("|cffff3333[KuiNameplates]|r There's no text to import.")
    return
  end

  local decoded = LibDeflate:DecodeForPrint(input)
  if not decoded then
    print("|cffff3333[KuiNameplates]|r Invalid code (decode).")
    return
  end

  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then
    print("|cffff3333[KuiNameplates]|r Invalid code (decompress).")
    return
  end

  local success, data = LibSerialize:Deserialize(decompressed)
  if not success or type(data) ~= "table" then
    print("|cffff3333[KuiNameplates]|r Invalid code (deserialize).")
    return
  end

  local dst = getProfileTable()
  if mode == "replace" then
    for k in pairs(dst) do dst[k] = nil end
    for k, v in pairs(data) do dst[k] = v end
  else
    deepMerge(dst, data)
  end

  print("|cff33ff99[KuiNameplates]|r Profile successfully imported (" .. (mode or "merge") .. ").")
  ReloadUI()
end

-- Integrating import/export inside of profiles tab

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local function AddImportExportToProfiles()
  local optionsObj = AceConfigRegistry:GetOptionsTable("kuinameplates")
  if not optionsObj then return end

  local options = type(optionsObj) == "function"
      and optionsObj("dialog", "AceConfigDialog-3.0")
      or optionsObj

  if not options or not options.args or not options.args.profiles then return end

  options.args.profiles.args.importexport = {
    type = "group",
    name = "Import/Export",
    inline = true,
    order = 99,
    args = {
      export = {
        type = "execute",
        name = "Export Profile",
        order = 1,
        func = function()
          local code = KuiNameplates:ExportProfile()
          if not code then return end
          StaticPopupDialogs["KUI_IE_EXPORT"] = {
            text = "Copy this text:",
            button1 = OKAY,
            hasEditBox = true,
            editBoxWidth = 350,
            OnShow = function(self)
              self.editBox:SetText(code or "")
              self.editBox:HighlightText()
            end,
            OnAccept = function(self) self.editBox:SetText("") end,
            timeout = 0, whileDead = true, hideOnEscape = true,
          }
          StaticPopup_Show("KUI_IE_EXPORT")
        end,
      },
      import = {
        type = "input",
        name = "Import Profile",
        multiline = true,
        width = "full",
        order = 2,
        set = function(_, val)
          KuiNameplates:ImportProfileFromString(val, "replace")
        end,
        get = function() return "" end,
      },
    },
  }
end

C_Timer.After(2, AddImportExportToProfiles)