param(
    [string]$VaultPath = "C:\obsidian\Main\0E2A~1",
    [string]$VaultFull = "C:\obsidian\Main\Англиский",
    [switch]$DryRun,
    [switch]$Force,
    [int]$MaxWords = 0
)

$ErrorActionPreference = 'Stop'
$vaultPath = $VaultPath
$vaultFull = $VaultFull

. (Join-Path $PSScriptRoot 'VaultHelpers.ps1')

$abstractions = @{
    "Emotion" = @("positive_emotions", "negative_emotions")
    "Action" = @("actions")
    "Cognition" = @("abstract_concepts")
    "Relation" = @("abstract_concepts")
    "Quality" = @("abstract_concepts")
    "Change" = @("abstract_concepts", "actions")
    "Object" = @("objects")
    "State" = @("abstract_concepts", "positive_emotions", "negative_emotions")
    "Abstract" = @("abstract_concepts")
}

$words = @{
    positive_emotions = @(
        "happy","joyful","pleased","grateful","excited","calm","peaceful","content","cheerful",
        "delighted","elated","ecstatic","euphoric","thrilled","overjoyed","blissful","radiant",
        "optimistic","enthusiastic","energetic","lively","playful","humorous","amused","entertained",
        "fascinated","interested","curious","inspired","motivated","determined","confident","proud",
        "satisfied","fulfilled","accomplished","successful","prosperous","wealthy","blessed",
        "fortunate","lucky","charmed","magical","wonderful","fantastic","amazing","incredible",
        "marvelous","splendid","glorious","beautiful","lovely","charming","delightful","pleasant",
        "agreeable","kind","gentle","sweet","tender","caring","loving","affectionate","warm",
        "friendly","sociable","outgoing","bubbly","vivacious","vibrant","dynamic","spirited",
        "passionate","ardent","eager","keen","zealous","devoted","dedicated","committed","loyal",
        "faithful","honest","sincere","genuine","authentic","pure","innocent","virtuous","moral",
        "ethical","righteous","noble","dignified","honorable","respectable","admirable","worthy",
        "valuable","precious","treasured","cherished","beloved","dear","special","unique",
        "extraordinary","exceptional","outstanding","remarkable","notable","distinguished","eminent",
        "prominent","famous","renowned","celebrated","acclaimed","admired","respected","revered",
        "adored","exalted","elevated","sublime","transcendent","divine","heavenly","celestial",
        "ethereal","spiritual","mystical","enchanting","mesmerizing","captivating","spellbinding",
        "riveting","gripping","absorbing","engaging","compelling","intriguing","stimulating",
        "inspiring","uplifting","heartening","encouraging","reassuring","comforting","soothing",
        "relaxing","restful","tranquil","serene","placid","still","quiet","silent","hushed",
        "muted","subdued","mild","soft","delicate","subtle","refined","polished","elegant",
        "graceful","poised","composed","collected","centered","balanced","harmonious","symmetrical",
        "proportional","perfect","ideal","optimal","best","finest","supreme","ultimate","paramount",
        "foremost","leading","top","highest","greatest","magnificent","majestic","grand","impressive",
        "stunning","striking","dazzling","brilliant","luminous","shining","glowing","sparkling",
        "glittering","shimmering","gleaming","glistening","twinkling","resplendent","lustrous",
        "glossy","shiny","bright","vivid","deep","intense","powerful","strong","robust","sturdy",
        "solid","firm","steady","stable","secure","safe","protected","sheltered","guarded",
        "defended","fortified","reinforced","strengthened","empowered","enabled","capable",
        "competent","skilled","talented","gifted","expert","masterful","proficient","adept",
        "sophisticated","cultured","educated","knowledgeable","wise","insightful","perceptive",
        "discerning","shrewd","astute","clever","intelligent","smart","bright","sharp","quick",
        "efficient","productive","effective","useful","helpful","beneficial","advantageous",
        "profitable","rewarding","fruitful","fertile","plentiful","abundant","ample","generous",
        "lavish","luxurious","opulent","sumptuous","extravagant","jubilant","exuberant","buoyant",
        "carefree","untroubled","serendipitous","felicitous","auspicious","propitious","affable",
        "amiable","benign","benevolent","altruistic","magnanimous","gregarious","cordial","genial"
    )
    negative_emotions = @(
        "sad","angry","anxious","depressed","frustrated","fearful","scared","terrified","horrified",
        "panicked","distressed","upset","troubled","worried","concerned","uneasy","uncomfortable",
        "tense","stressed","overwhelmed","burdened","helpless","hopeless","despairing","despondent",
        "disheartened","discouraged","demoralized","defeated","crushed","shattered","broken",
        "devastated","ruined","destroyed","desolate","isolated","alone","lonely","lonesome",
        "forsaken","abandoned","neglected","ignored","overlooked","forgotten","dismissed",
        "rejected","spurned","scorned","despised","hated","loathed","detested","abhorred",
        "reviled","cursed","damned","doomed","condemned","sentenced","punished","tortured",
        "tormented","agonized","anguished","suffering","miserable","wretched","pathetic","pitiful",
        "pitiable","lamentable","regrettable","unfortunate","unlucky","hapless","jinxed",
        "ill-fated","tragic","catastrophic","disastrous","calamitous","ruinous","devastating",
        "crushing","overwhelming","staggering","shocking","appalling","horrifying","terrifying",
        "frightening","alarming","disturbing","disquieting","unsettling","disconcerting",
        "troubling","worrying","vexing","irritating","annoying","bothersome","troublesome",
        "exasperating","infuriating","enraging","maddening","provoking","explosive","volatile",
        "unstable","unbalanced","unhinged","deranged","demented","insane","crazy","mad",
        "lunatic","psychotic","neurotic","obsessive","compulsive","addicted","dependent",
        "enslaved","trapped","imprisoned","confined","restricted","limited","constrained",
        "restrained","suppressed","repressed","oppressed","persecuted","victimized","targeted",
        "alienated","estranged","separated","divided","split","torn","conflicted","confused",
        "bewildered","baffled","perplexed","puzzled","mystified","dumbfounded","stunned",
        "dazed","disoriented","adrift","aimless","directionless","purposeless","meaningless",
        "hollow","vain","futile","pointless","useless","worthless","valueless","insignificant",
        "unimportant","trivial","petty","minor","irrelevant","inconsequential","unremarkable",
        "ordinary","common","average","mediocre","inferior","dreadful","horrible","horrendous",
        "horrific","gruesome","grisly","grim","bleak","gloomy","dreary","dismal","somber",
        "dark","shadowy","murky","cloudy","overcast","foggy","misty","hazy","blurry",
        "uncertain","unsure","doubtful","dubious","questionable","suspicious","wary","cautious",
        "guarded","defensive","hostile","antagonistic","adversarial","confrontational",
        "combative","aggressive","violent","brutal","savage","cruel","vicious","mean","nasty",
        "spiteful","malicious","malevolent","evil","wicked","sinister","corrupt","depraved",
        "degenerate","immoral","unethical","dishonest","deceitful","fraudulent","treacherous",
        "traitorous","disloyal","unfaithful","faithless","unreliable","untrustworthy",
        "irresponsible","negligent","reckless","careless","thoughtless","inconsiderate","rude",
        "impolite","disrespectful","insolent","arrogant","haughty","conceited","narcissistic",
        "selfish","greedy","gluttonous","envious","jealous","possessive","controlling",
        "manipulative","calculating","scheming","plotting","conspiring","devious","underhanded",
        "sneaky","sly","cunning","crafty","wily","tricky","deceitful","belligerent","contentious",
        "petulant","irritable","cranky","grumpy","sullen","morose","glum","surly","testy",
        "touchy","crabby","crotchety","ornery","peevish","fretful","whiny","complaining",
        "resentful","bitter","acrimonious","caustic","scathing","vitriolic","indignant","irked"
    )
    actions = @(
        "run","walk","laugh","smile","cry","jump","hop","skip","leap","bound","dash","sprint",
        "jog","march","stride","stroll","wander","roam","travel","journey","migrate","move",
        "shift","change","transform","evolve","grow","develop","progress","advance","proceed",
        "continue","persist","endure","survive","thrive","flourish","bloom","blossom","flower",
        "ripen","mature","age","decay","rot","wither","shrink","contract","expand","extend",
        "reach","stretch","bend","twist","turn","spin","rotate","revolve","orbit","circle",
        "loop","coil","curl","wave","flow","stream","pour","gush","rush","race","fly","soar",
        "glide","drift","float","sink","dive","plunge","drop","fall","tumble","roll","slide",
        "slip","skid","stumble","trip","crash","collide","hit","strike","punch","kick","slap",
        "push","pull","drag","haul","carry","lift","raise","lower","throw","catch","grab",
        "grasp","hold","grip","squeeze","press","tug","yank","jerk","shake","tremble","shudder",
        "shiver","quiver","quake","vibrate","oscillate","swing","sway","rock","bounce","dance",
        "sing","hum","whistle","whisper","shout","scream","yell","sob","weep","moan","groan",
        "sigh","yawn","sneeze","cough","hiccup","breathe","inhale","exhale","pant","gasp",
        "wheeze","choke","swallow","eat","drink","chew","bite","nibble","sip","gulp","devour",
        "consume","digest","absorb","assimilate","process","eliminate","sweat","bleed","heal",
        "recover","rest","sleep","dream","wake","rise","arise","stand","sit","lie","recline",
        "lean","kneel","crouch","squat","crawl","creep","sneak","slither","swim","paddle",
        "row","sail","navigate","steer","drive","ride","cycle","pedal","pilot","command","lead",
        "guide","direct","manage","control","operate","administer","organize","arrange","sort",
        "classify","categorize","group","assemble","gather","collect","accumulate","amass",
        "stockpile","hoard","save","store","keep","maintain","preserve","protect","defend",
        "guard","shield","shelter","hide","conceal","cover","reveal","expose","uncover","show",
        "display","exhibit","present","demonstrate","illustrate","explain","describe","narrate",
        "recount","report","inform","notify","warn","alert","signal","indicate","signify",
        "suggest","recommend","advise","counsel","mentor","teach","educate","train","coach",
        "tutor","instruct","lecture","preach","debate","argue","discuss","talk","speak",
        "converse","communicate","interact","connect","link","join","unite","combine","merge",
        "fuse","blend","mix","stir","whisk","beat","whip","fold","knead","shape","form",
        "mold","sculpt","carve","chisel","engrave","etch","draw","paint","color","shade",
        "tint","dye","stain","coat","layer","stack","pile","heap","build","construct",
        "erect","raise","elevate","hoist","heave","toss","fling","hurl","cast","launch",
        "shoot","fire","blast","explode","detonate","ignite","burn","flame","blaze","glow",
        "shine","radiate","emit","discharge","release","free","liberate","rescue","save",
        "help","assist","aid","support","sustain","nurture","foster","cultivate","grow",
        "plant","sow","harvest","reap","pick","pluck","extract","remove","delete","erase",
        "eliminate","destroy","demolish","raze","level","flatten","smash","break","crack",
        "split","divide","separate","part","sever","cut","slice","chop","dice","mince",
        "grate","shred","tear","rip","rend","pierce","puncture","stab","stick","poke","prod",
        "jab","nudge","tap","pat","stroke","caress","hug","embrace","kiss","cuddle","snuggle",
        "nestle","nuzzle","lick","suck","blow","puff","sniff","smell","taste","flavor",
        "savor","relish","enjoy","delight","please","satisfy","gratify","indulge","pamper",
        "spoil","treat","reward","compensate","pay","reimburse","refund","repay","return",
        "give","donate","contribute","provide","supply","furnish","equip","outfit","prepare",
        "ready","set","fix","repair","mend","restore","renovate","refurbish","remodel",
        "redesign","rebuild","reconstruct","recreate","refresh","renew","revive","rejuvenate",
        "regenerate","pursue","chase","hunt","seek","search","find","locate","discover",
        "uncover","unearth","reveal","explore","investigate","examine","inspect","scrutinize",
        "analyze","study","research","review","assess","evaluate","judge","rate","rank",
        "grade","score","measure","calculate","compute","count","enumerate","list","itemize",
        "catalog","register","record","document","log","chart","graph","map","plot","trace",
        "track","follow","shadow","tail","pursue","chase","hunt","stalk","trail","monitor",
        "watch","observe","view","witness","see","look","notice","detect","perceive","discern"
    )
    objects = @(
        "book","house","tree","water","fire","stone","rock","mountain","river","ocean","sea",
        "lake","pond","stream","brook","creek","hill","valley","field","forest","wood","jungle",
        "desert","plain","plateau","island","peninsula","cape","bay","gulf","harbor","port",
        "dock","pier","wharf","quay","beach","shore","coast","bank","border","boundary",
        "frontier","pillar","column","arch","dome","tower","spire","steeple","chimney","pipe",
        "tube","hose","cable","wire","rope","cord","string","thread","yarn","fabric","cloth",
        "textile","material","substance","element","compound","mixture","alloy","blend",
        "composite","hybrid","bridge","tunnel","passage","corridor","hall","room","chamber",
        "cell","compartment","cubicle","booth","stall","kiosk","stand","table","desk","chair",
        "stool","bench","couch","sofa","bed","mattress","pillow","blanket","sheet","cover",
        "rug","carpet","mat","floor","wall","ceiling","roof","door","window","gate","fence",
        "barrier","hedge","screen","curtain","drape","blind","shutter","lock","key","handle",
        "knob","latch","bolt","hinge","joint","seam","stitch","button","zipper","buckle",
        "clasp","hook","eye","loop","ring","chain","link","mesh","net","web","network","grid",
        "lattice","grate","grill","rack","shelf","cabinet","cupboard","closet","chest","box",
        "crate","barrel","drum","can","tin","jar","bottle","flask","jug","pitcher","pot",
        "pan","kettle","teapot","cup","mug","glass","goblet","bowl","plate","dish","saucer",
        "tray","platter","basket","bag","sack","pouch","purse","wallet","backpack","suitcase",
        "trunk","drawer","bin","bucket","pail","tub","basin","sink","faucet","tap","valve",
        "pump","engine","motor","turbine","generator","dynamo","battery","capacitor","resistor",
        "inductor","transformer","amplifier","speaker","microphone","antenna","receiver",
        "transmitter","radio","television","monitor","screen","display","panel","board",
        "console","keyboard","mouse","printer","scanner","copier","phone","telephone",
        "smartphone","tablet","computer","laptop","notebook","server","router","switch","hub",
        "modem","plug","socket","outlet","button","dial","lever","pedal","crank","wheel",
        "axle","shaft","gear","pulley","belt","chain","sprocket","cam","piston","cylinder",
        "nozzle","spray","sprinkler","shower","bath","tub","pool","spa","sauna","steam",
        "rain","snow","ice","hail","sleet","frost","dew","drop","splash","vapor","gas","air",
        "atmosphere","sky","heaven","space","universe","cosmos","galaxy","star","planet",
        "moon","sun","earth","world","globe","sphere","ball","orb","circle","square","triangle",
        "rectangle","polygon","pattern","institution","establishment","foundation","society",
        "community","group","team","crew","gang","band","party","company","corporation","firm",
        "business","enterprise","venture","project","program","plan","scheme","strategy",
        "tactic","approach","path","route","course","track","trail","road","street","avenue",
        "boulevard","lane","alley","sidewalk","pavement","highway","freeway","expressway",
        "turnpike","overpass","underpass","crossing","intersection","junction","roundabout",
        "plaza","court","yard","garden","park","playground","stadium","arena","theater",
        "cinema","museum","gallery","library","school","college","university","academy",
        "institute","center","facility","plant","factory","mill","workshop","studio","lab",
        "laboratory","office","store","shop","market","mall","depot","station","terminal",
        "airport","seaport","marina","shipyard","apartment","cottage","cabin","shack","hut",
        "tent","castle","palace","mansion","villa","estate","farm","barn","stable","shed",
        "warehouse","garage","shelter","canopy","pavilion","gazebo","deck","porch","patio",
        "balcony","terrace","step","stair","ladder","elevator","escalator","ramp","conveyor",
        "crane","winch","hoist","jack","lever","wedge","screw","wrench","hammer","screwdriver",
        "pliers","chisel","plane","saw","drill","file","rasp","sandpaper","brush","broom",
        "mop","sponge","cloth","towel","rag","napkin","tissue","paper","cardboard","plastic",
        "rubber","leather","wool","silk","cotton","linen","polyester","nylon","velvet","satin",
        "lace","denim","canvas","felt","brick","concrete","cement","plaster","mortar","asphalt",
        "tar","gravel","sand","clay","mud","dust","ash","soot","cinder","charcoal","coal",
        "ore","metal","steel","iron","copper","brass","bronze","aluminum","tin","zinc","lead",
        "silver","gold","platinum","diamond","ruby","emerald","sapphire","amethyst","opal",
        "jade","crystal","quartz","granite","marble","slate","limestone","sandstone","basalt",
        "obsidian","flint","amber","ivory","bone","horn","shell","pearl","coral","feather",
        "fur","hair","skin","paper","cardboard","ribbon","wire","foil","film","gel","paste"
    )
    abstract_concepts = @(
        "freedom","love","hope","time","peace","justice","truth","beauty","wisdom","knowledge",
        "understanding","compassion","empathy","sympathy","kindness","generosity","charity",
        "mercy","forgiveness","grace","honor","dignity","respect","admiration","appreciation",
        "gratitude","thankfulness","joy","happiness","bliss","ecstasy","delight","pleasure",
        "satisfaction","contentment","fulfillment","achievement","success","victory","triumph",
        "glory","fame","fortune","wealth","prosperity","abundance","plenty","surplus","excess",
        "luxury","comfort","ease","leisure","relaxation","tranquility","serenity","harmony",
        "balance","equilibrium","stability","security","safety","protection","defense","shelter",
        "refuge","sanctuary","haven","oasis","paradise","utopia","nirvana","enlightenment",
        "illumination","clarity","insight","vision","foresight","hindsight","awareness",
        "consciousness","mindfulness","attention","focus","concentration","meditation",
        "contemplation","reflection","thought","reasoning","logic","rationality","intellect",
        "intelligence","genius","brilliance","creativity","imagination","fantasy","dream",
        "aspiration","ambition","goal","objective","target","aim","purpose","meaning",
        "significance","importance","value","worth","merit","excellence","quality","standard",
        "benchmark","criterion","measure","metric","indicator","signal","sign","symbol","emblem",
        "token","representation","expression","manifestation","embodiment","incarnation",
        "personification","essence","nature","character","personality","identity","self","soul",
        "spirit","heart","mind","psyche","conscience","morality","ethics","virtue",
        "righteousness","integrity","honesty","truthfulness","sincerity","authenticity",
        "genuineness","transparency","openness","vulnerability","courage","bravery","valor",
        "heroism","gallantry","chivalry","nobility","prestige","status","rank","position",
        "authority","power","influence","control","dominance","supremacy","mastery","command",
        "leadership","guidance","direction","management","administration","governance","rule",
        "law","order","discipline","regulation","policy","principle","doctrine","dogma","creed",
        "faith","belief","religion","spirituality","divinity","sacredness","holiness","purity",
        "innocence","modesty","humility","meekness","gentleness","tenderness","softness",
        "mildness","patience","tolerance","endurance","perseverance","persistence","determination",
        "resolve","dedication","commitment","devotion","loyalty","fidelity","allegiance",
        "obedience","submission","surrender","sacrifice","offering","gift","donation",
        "contribution","participation","involvement","engagement","investment","stake","share",
        "portion","part","piece","fragment","segment","section","division","partition",
        "separation","isolation","solitude","loneliness","alienation","estrangement","distance",
        "space","gap","void","emptiness","nothingness","abyss","chasm","gulf","rift","split",
        "discord","disharmony","conflict","strife","struggle","fight","battle","war","tension",
        "stress","pressure","strain","burden","weight","load","responsibility","duty","obligation",
        "requirement","necessity","need","demand","desire","want","wish","drive","motivation",
        "inspiration","stimulus","incentive","encouragement","support","assistance","aid","help",
        "relief","comfort","solace","consolation","information","data","facts","evidence","proof",
        "confirmation","verification","validation","certification","accreditation","authorization",
        "permission","consent","approval","endorsement","sanction","support","backing",
        "sponsorship","patronage","guardianship","protection","care","custody","keeping",
        "preservation","conservation","maintenance","upkeep","repair","restoration","renovation",
        "revival","renewal","regeneration","rebirth","resurrection","reincarnation",
        "transformation","change","evolution","development","growth","progress","advancement",
        "improvement","enhancement","enrichment","refinement","cultivation","nurture","fostering",
        "promotion","furtherance","advocacy","championing","defense","imagination","curiosity",
        "wonder","awe","reverence","veneration","worship","adoration","devotion","piety",
        "sanctity","grace","blessing","miracle","mystery","magic","enchantment","spell","charm",
        "fate","destiny","providence","karma","fortune","luck","chance","coincidence","serendipity",
        "synchronicity","flow","rhythm","cycle","pattern","order","chaos","entropy","energy",
        "force","power","strength","might","potency","capacity","ability","capability","competence",
        "skill","talent","gift","flair","knack","aptitude","faculty","wisdom","sagacity","acuity",
        "sharpness","quickness","wit","humor","fancy","whim","caprice","impulse","urge","drive",
        "instinct","intuition","hunch","feeling","emotion","passion","ardor","fervor","zeal",
        "fire","heat","warmth","affection","fondness","tenderness","concern","care","regard",
        "esteem","value","worth","dignity","honor","respect","deference","homage","tribute",
        "praise","acclaim","applause","recognition","notice","attention","awareness",
        "consciousness","sense","perception","sensation","feeling","sentiment","emotion",
        "passion","affection","attachment","bond","connection","relation","relationship","tie",
        "link","association","union","marriage","partnership","alliance","coalition","federation",
        "league","guild","order","brotherhood","sisterhood","fellowship","companionship",
        "friendship","camaraderie","solidarity","unity","oneness","wholeness","completeness",
        "totality","entirety","fullness","richness","depth","breadth","width","scope","range",
        "reach","extent","magnitude","scale","degree","level","standard","quality","class",
        "grade","rank","status","position","standing","footing","ground","basis","foundation",
        "base","root","source","origin","beginning","start","commencement","birth","creation",
        "genesis","dawn","rise","birth","inception","onset","outset","threshold","verge","brink",
        "edge","cusp","point","stage","phase","step","juncture","moment","instant","second",
        "minute","hour","day","week","month","year","decade","century","era","epoch","age",
        "period","duration","term","span","stretch","interval","interim","meantime","meanwhile",
        "pause","break","hiatus","interruption","interlude","leap","jump","bound","vault","skip"
    )
}

$wordToAbstractions = @{}
$abstractionNames = @($abstractions.Keys)
$abstractionNamesLower = $abstractionNames | ForEach-Object { $_.ToLower() }

$rng = [System.Random]::new(42)
$generatedWords = 0

foreach ($cat in $words.Keys) {
    $availableAbstractions = @()
    foreach ($a in $abstractions.Keys) {
        if ($cat -in $abstractions[$a]) {
            $availableAbstractions += $a
        }
    }
    Write-Host "$cat -> $($availableAbstractions -join ', ')"

    foreach ($w in $words[$cat]) {
        $w = $w.ToLower().Trim()
        if ($w -in $abstractionNamesLower) { continue }
        $count = $rng.Next(1, 4)
        $selected = @()
        $pool = @($availableAbstractions)
        for ($i = 0; $i -lt $count -and $pool.Count -gt 0; $i++) {
            $idx = $rng.Next(0, $pool.Count)
            $selected += $pool[$idx]
            $pool = @($pool | Where-Object { $_ -ne $pool[$idx] })
        }
        $wordToAbstractions[$w] = $selected
        $generatedWords++
        if ($MaxWords -gt 0 -and $generatedWords -ge $MaxWords) {
            break
        }
    }
    if ($MaxWords -gt 0 -and $generatedWords -ge $MaxWords) {
        break
    }
}
$abstractionFiles = $abstractionNames | ForEach-Object { $_ + ".md" }
$oldFiles = Get-ChildItem -LiteralPath $vaultPath -Filter "*.md" | Where-Object { $_.Name -notin $abstractionFiles }
$targetFiles = @($wordToAbstractions.Keys | Sort-Object | ForEach-Object { Join-Path $vaultPath "$_.md" })

Assert-SafeBulkOperation -Operation 'generate_terms_v2 cleanup' -Root $vaultPath -TargetPaths $oldFiles -DryRun:$DryRun -Force:$Force -Destructive
Assert-SafeBulkOperation -Operation 'generate_terms_v2 generation' -Root $vaultPath -TargetPaths $targetFiles -DryRun:$DryRun -Force:$Force -MaxWriteCount 5000

foreach ($f in $oldFiles) {
    if (-not $DryRun) {
        Remove-Item -LiteralPath $f.FullName -Force
    }
}

$count = 0
$total = $wordToAbstractions.Count
foreach ($word in ($wordToAbstractions.Keys | Sort-Object)) {
    $abs = $wordToAbstractions[$word]
    $lines = @()
    $lines += "---"
    $lines += "type: term"
    $lines += "---"
    $lines += ""
    $lines += "# $word"
    $lines += ""
    $lines += "## Abstractions"
    foreach ($a in $abs) {
        $lines += "[[$a]]"
    }
    $lines += ""

    $content = $lines -join "`n"
    $fileName = "$vaultPath\$word.md"
    if (-not $DryRun) {
        Assert-SafeBulkOperation -Operation 'generate_terms_v2 term write' -Root $vaultPath -TargetPaths @($fileName) -DryRun:$DryRun -Force:$Force -MaxWriteCount 5000
        Write-Utf8Text -Path $fileName -Content $content -Bom
    }

    $count++
    if ($count % 100 -eq 0) {
        Write-Host "  $count / $total generated..."
    }
}

Write-Host "Done! Generated $count term files."
Write-Host "Abstractions: $($abstractionNames.Count)"
