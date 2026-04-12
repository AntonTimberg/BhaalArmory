# BhaalGifts — справочник модостроения

## 1. Визуалы предметов

### Подход "vanilla parent" (кинжал, кольцо, амулет)
Для слотов с простой моделью (оружие, кольцо, амулет):
- В `BhaalGifts.lsx` ставим `ParentTemplateId` = vanilla UUID
- Минимальный node: MapKey + Name + Stats + Type + ParentTemplateId + DisplayName + Description + `<node id="Bounds"/>`
- Визуал наследуется от vanilla, имя/описание наши

### Подход "чужой мод как submodule" (Body Armor — Black Hand)
Для кастомных 3D-моделей из чужих модов:
- LSF файлы внутри Content содержат **hardcoded пути** (`Generated/Public/<ModFolder>/Assets/Models/...`)
- Переименование namespace ломает пути — нельзя перенести в `Public/BhaalGifts/`
- **Решение**: копируем всю структуру мода (Public/, Generated/, Mods/meta.lsx) в `build/` как есть, сохраняя оригинальное имя папки
- В `build/Mods/<OriginalModFolder>/meta.lsx` кладём оригинальный meta — игра регистрирует его как второй модуль в нашем pak
- В `build/Public/<OriginalModFolder>/` — Assets, Content, VirtualTextures, RootTemplates (без Stats — они конфликтуют)
- В `build/Generated/Public/<OriginalModFolder>/` — Models, VirtualTextures
- Наш body node в `BhaalGifts.lsx` **копирует** полный Equipment/Visuals блок из чужого мода (5 body-type маппингов), а не просто наследуется через ParentTemplateId
- `VisualTemplate` явно прописан (UUID из чужого мода)

Пример рабочего body node:
```xml
<attribute id="ParentTemplateId" value="67a87879-..."/>  <!-- vanilla base -->
<attribute id="VisualTemplate" value="589b3bc4-..."/>     <!-- из Black Hand -->
<node id="Equipment">
    <node id="Visuals">
        <!-- 5 объектов: по одному на body type (MapKey=body_type_guid, MapValue=visual_guid) -->
    </node>
    <node id="Slot"><attribute id="Object" value="Body"/></node>
</node>
```

### Невидимые предметы (перчатки, сапоги)
Когда body-модель покрывает всё тело:
- `ParentTemplateId` = `67a87879-533e-4f9b-8274-f5bd37748ace` (generic vanilla item base)
- `VisualTemplate` = `""` (пустая строка)
- Equipment/Visuals node **пустой** (без children)
- Slot = "Boots" / "Gloves" (явно, иначе не экипируется в слот)
- Icon явно задан (vanilla иконка, напр. `Item_ARM_Boots_Leather`)

---

## 2. Иконки предметов

Иконки задаются в `BhaalGifts.lsx` через `<attribute id="Icon" value="..."/>`.

### Как найти правильное имя иконки
1. Найти vanilla root template предмета-аналога:
   ```bash
   grep -n "443b2caf" gustavdev_rt.lsx
   ```
2. В vanilla template найти атрибут `Icon`:
   ```
   <attribute id="Icon" value="Generated_MAG_Bhaalist_Armor_Magic"/>
   ```
3. Использовать это точное значение

### Рабочие иконки
| Предмет       | Иконка                                   |
|---------------|------------------------------------------|
| Кинжал        | `Item_WPN_DROW_Dagger_Dolor_A`           |
| Доспех        | `Generated_MAG_Bhaalist_Armor_Magic`     |
| Сапоги (инвиз)| `Item_ARM_Boots_Leather`                |
| Перчатки (инвиз)| `Item_ARM_Gloves_Leather`             |

Если иконка = `?` в игре — имя не найдено в vanilla ресурсах. Не выдумывать имена — искать в `gustavdev_rt.lsx` или в extracted root templates.

---

## 3. Статы на броне

### Boosts — что НЕ класть напрямую в Armor.txt Boosts
`DamageReduction(All, Flat, 3)` в Boosts показывается как голый текст "All" без описания.

**Решение**: выносить в пассивку с DisplayName/Description:
```
new entry "BG_DamageReduction"
type "PassiveData"
data "DisplayName" "hbg_dmg_reduction_name"
data "Description" "hbg_dmg_reduction_desc"
data "DescriptionParams" "3"
data "Icon" "PassiveFeature_Generic_Defensive"
data "Properties" "Highlighted"
data "Boosts" "DamageReduction(All, Flat, 3)"
```
Важно: `DescriptionParams "3"` подставляется в `[1]` в тексте описания.

### Спасброски +N ко всем
Не перечислять 6 отдельных строк — BG3 поддерживает:
```
RollBonus(SavingThrow, 2)
```
Без третьего аргумента = все спасброски. Одна строка в тултипе.

### Exotic Material (полный Dex + нет штрафа Stealth)
Паттерн Yuan-Ti Scale Mail / Bhaalist Armor:
```
data "Ability Modifier Cap" ""               ← снимает кэп +2 Dex на medium armor
data "StatusOnEquip" "MAG_EXOTIC_MATERIAL_ARMOR_TECHNICAL"  ← vanilla статус, убирает stealth disadvantage
data "PassivesOnEquip" "BG_ExoticMaterial"   ← наша пассивка-описание (без бустов, чисто текст)
```

### Перебивание унаследованных пассивок
`PassivesOnEquip` в child entry **ЗАМЕНЯЕТ** parent целиком. Если у `ARM_StuddedLeather_Body_2` есть `PassivesOnEquip "ARM_Ambusher_2_Passive;..."`, а у нас:
```
data "PassivesOnEquip" "BG_ExoticMaterial;BG_DamageReduction"
```
— то Ambusher пропадает. Наши пассивки заменяют, не дополняют.

### Пробелы в Boosts
**Всегда** ставить пробелы после запятых: `DamageReduction(All, Flat, 3)`, не `DamageReduction(All,Flat,3)`. Vanilla использует пробелы — парсер может не распознать без них.

---

## 4. Спеллы и способности

### SpellType "Shout" vs "Target"
- **Shout** — на себя, без выбора цели (Проекции, Аура). Всегда доступен вне/в бою.
- **Target** — на точку/цель (Shadow Step, Corpse Explosion). Тоже доступен вне боя, НО:
  - **НЕ наследовать от чужих спеллов** (`using "Target_MAG_Legendary_HellCrawler"`) — тянут скрытые ограничения, combat-only флаги, зависшие анимации
  - Писать **с нуля**, копируя анимации/эффекты по UUID из рабочего шаблона

### Рабочий шаблон Target-телепорта (Shadow Step)
```
new entry "Target_BhaalShadowStep"
type "SpellData"
data "SpellType" "Target"
data "Level" ""
data "SpellSchool" ""
data "Cooldown" "OncePerCombat"
data "TargetRadius" "18"
data "SpellProperties" "GROUND:TeleportSource();SELF:ApplyStatus(BG_SHADOW_CRIT,100,1)"
data "TargetConditions" "CanStand('') and not Character() and not Self()"
data "Icon" "Action_Monk_ShadowStep"
data "DisplayName" "..."
data "Description" "..."
data "CastSound" "Spell_Cast_Monk_ShadowStep_L1to3"
data "TargetSound" "Spell_Impact_Monk_ShadowStep_L1to3"
data "PreviewCursor" "Cast"
data "CastTextEvent" "Cast"
data "UseCosts" "BonusActionPoint:1"
data "SpellAnimation" "03496c4a-...(та же что у Projections)"
data "VerbalIntent" "Utility"
data "SpellFlags" "HasHighGroundRangeExtension;RangeIgnoreVerticalThreshold;IsSpell;HasSomaticComponent"
data "HitAnimationType" "MagicalNonDamage"
data "PrepareEffect" "a0458d31-f8ef-419a-8708-5715c81e91d3"
data "CastEffect" "52af7a1d-d5d9-4506-85ce-d124f1ef9ea5"
```

### Рабочий шаблон AoE-взрыва (Corpse Explosion)
```
data "SpellProperties" "TARGET:SwitchDeathType(Explode);CreateExplosion(Projectile_BhaalCorpseExplosion_Explosion)"
data "TargetConditions" "Dead()"
```
Вспомогательный Projectile_* делает DealDamage в AreaRadius. Без него DealDamage на трупе не расходится AoE.

### Cooldown-ы
- `OncePerCombat` — раз за бой. **Работает и вне боя** (ресетится при завершении боя). Если спелл всё равно серый вне боя — проблема в `using` наследовании, не в кулдауне.
- `OncePerShortRest` — раз за короткий отдых.
- `OncePerShortRestPerItem` — Helldusk Boots паттерн.

### Гарантированный крит после каста
Статус `BOOST` с `CriticalHit(AttackTarget,Success,Always)` + `RemoveEvents "OnAttack"`:
```
new entry "BG_SHADOW_CRIT"
type "StatusData"
data "StatusType" "BOOST"
data "Boosts" "CriticalHit(AttackTarget,Success,Always)"
data "RemoveEvents" "OnAttack"
```
Применяется через `SELF:ApplyStatus(BG_SHADOW_CRIT,100,1)` в SpellProperties.

### Damage-on-hit пассивки
```
data "StatsFunctorContext" "OnDamage"                      ← НЕ "OnAttack"
data "Conditions" "AttackedWithPassiveSourceWeapon()"       ← только оружие с этой пассивкой
data "StatsFunctors" "ApplyStatus(SILENCED,100,2)"
```
`OnAttack` — до урона, нестабильно для статусов. `OnDamage` — после попадания, надёжно.

### Level-gated способности
```
data "RequirementConditions" "CharacterLevelGreaterThan(9)"   ← для спелла
data "Boosts" "IF(CharacterLevelGreaterThan(3)):CharacterWeaponDamage(6)"  ← для пассивки
```

---

## 5. Stat bases — валидные `using`

### Проверенные рабочие
| Слот     | База                        | Тип            |
|----------|-----------------------------|----------------|
| Тело     | `ARM_StuddedLeather_Body_2` | Light Armor    |
| Перчатки | `_Hand_Magic_Metal`         | Gloves         |
| Сапоги   | `_Foot_Magic_Metal`         | Boots          |
| Кольцо   | `ARM_Ring`                  | Ring           |
| Амулет   | `ARM_Amulet`                | Amulet         |
| Кинжал   | `WPN_Dagger`                | Weapon         |

### Нерабочие (ломают парсинг)
`_Foot`, `_Hand`, `ARM_Robe_Body`, `ARM_Leather_Body` — не существуют как stat entries, хотя интуитивно кажутся валидными.

Если сломан `using` в ОДНОЙ записи — вся запись не парсится, предмет не создаётся, Equipment.txt его тихо пропускает. Соседние записи обычно не ломаются.

---

## 6. Сборка и деплой

### Структура build/
```
build/
├── Mods/
│   ├── BhaalGifts/meta.lsx
│   └── Black_Hand_Armor_.../meta.lsx        ← submodule для визуалов
├── Public/
│   ├── BhaalGifts/
│   │   ├── RootTemplates/_merged.lsf
│   │   └── Stats/Generated/...
│   └── Black_Hand_Armor_.../                 ← модели, текстуры, Content
├── Generated/
│   └── Public/Black_Hand_Armor_.../          ← скомпиленные модели
└── Localization/
    ├── Russian/BhaalGifts.loca
    └── English/BhaalGifts.loca
```

### Команды сборки (абсолютные пути!)
```bash
SRC="c:/Users/The Belltower/Desktop/barathro/mods/bg3-bhaal-gifts"
DIVINE="c:/Users/The Belltower/Desktop/barathro/mods/bg3-dark-apostle/tools/LSLib/Packed/Tools/Divine.exe"

# 1. Скопировать source → build
cp $SRC/Public/BhaalGifts/Stats/Generated/Data/*.txt $SRC/build/Public/BhaalGifts/Stats/Generated/Data/
cp $SRC/Public/BhaalGifts/Stats/Generated/Equipment.txt $SRC/build/Public/BhaalGifts/Stats/Generated/
cp $SRC/Mods/BhaalGifts/meta.lsx $SRC/build/Mods/BhaalGifts/

# 2. Конвертация
$DIVINE -g bg3 -a convert-resource -s "$SRC/Public/BhaalGifts/RootTemplates/BhaalGifts.lsx" -d "$SRC/build/Public/BhaalGifts/RootTemplates/_merged.lsf" -i lsx -o lsf
$DIVINE -g bg3 -a convert-loca -s "$SRC/Localization/Russian/BhaalGifts.loca.xml" -d "$SRC/build/Localization/Russian/BhaalGifts.loca"
$DIVINE -g bg3 -a convert-loca -s "$SRC/Localization/English/BhaalGifts.loca.xml" -d "$SRC/build/Localization/English/BhaalGifts.loca"

# 3. Сборка + деплой
$DIVINE -g bg3 -a create-package -s "$SRC/build" -d "$SRC/BhaalGifts.pak"
cp "$SRC/BhaalGifts.pak" "$LOCALAPPDATA/Larian Studios/Baldur's Gate 3/Mods/"
```

**Divine.exe требует абсолютные пути!** Относительные → `[FATAL] Cannot proceed without absolute path`.

### Чек-лист после деплоя
1. В BG3 Mod Manager активированы **оба** мода: BhaalGifts + Black_Hand_Armor
2. **Новая игра** (Equipment.txt применяется только при создании персонажа)
3. Если предмет без визуала — проверить `_merged.lsf` регенерирован ли после правки .lsx
4. Если статы не изменились — проверить что Armor.txt скопирован в build/

---

## 7. Vanilla UUID справочник

### Root Templates (визуалы)
| Слот     | Предмет               | UUID                                   |
|----------|-----------------------|----------------------------------------|
| Тело     | Black Hand Body       | `d3f5a453-330b-47cb-8aa6-3736c1fb1cb3` |
| Тело     | Bhaalist Armor        | `443b2caf-8d36-42cf-b389-d774229ed18c` |
| Сапоги   | Helldusk Boots        | `bc82f909-ade5-4ada-9b94-cec7ca1d4a68` |
| Перчатки | Bhaalist Gloves       | `afd74d05-7c24-45ec-8033-84f365e6ea5f` |
| Кинжал   | Dolor's Dagger        | `e8df5166-5a68-42ec-b71f-4dfb754f7aa4` |
| Амулет   | Bhaal Amulet (Act 3)  | `16a632e2-45b1-4ff1-8250-513eb271abea` |
| Кольцо   | Generic Ring          | `0af630e0-82eb-4b83-baa2-e296f97a7a4e` |
| Item base| Generic Item          | `67a87879-533e-4f9b-8274-f5bd37748ace` |

### Наши MapKey
| Предмет    | MapKey UUID                              |
|------------|------------------------------------------|
| Кольцо     | `b3e8f1a2-4c7d-9e06-5f3b-8a2d1c6e4f09` |
| Кинжал     | `d5c7a9e1-3b2f-4d8a-6e0c-1f9a7b3d5e08` |
| Сапоги     | `a1c8d2e4-5f3b-4e7d-9a6c-1b8f2e4d7a09` |
| Перчатки   | `c2e7f5b8-4a6d-3c9e-8b1f-5d2a7c4e9b06` |
| Доспех     | `f8b3a6d2-9c5e-4f1b-a7d3-2e8c6b4f1a05` |
| Амулет     | `e9f1b3a5-7c2d-4e6f-8a0b-3d5c1e7f9a02` |
