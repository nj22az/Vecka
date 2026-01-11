//
//  QuirkyFacts.swift
//  Vecka
//
//  Region-based quirky facts for GLANCE tiles
//  情報デザイン: Say less with more
//

import Foundation

// MARK: - Data Model

struct QuirkyFact: Identifiable, Codable, Equatable {
    let id: String
    let region: String          // "SE", "VN", "UK", "US"
    let category: FactCategory
    let text: String            // Short, punchy - max ~30 chars for tile

    enum FactCategory: String, Codable {
        case tradition
        case food
        case invention
        case nature
        case history
        case quirky
    }
}

// MARK: - Facts Database

enum QuirkyFactsDB {

    // MARK: - Swedish Facts (Priority Region)

    static let sweden: [QuirkyFact] = [
        // Traditions & Culture
        QuirkyFact(id: "se001", region: "SE", category: .tradition, text: "Swedes count weeks, not dates"),
        QuirkyFact(id: "se002", region: "SE", category: .tradition, text: "Midsommar: dance around a maypole"),
        QuirkyFact(id: "se003", region: "SE", category: .tradition, text: "Easter = kids dress as witches"),
        QuirkyFact(id: "se004", region: "SE", category: .quirky, text: "Gävle Goat: burned yearly since 1966"),
        QuirkyFact(id: "se005", region: "SE", category: .quirky, text: "Tax office approves baby names"),
        QuirkyFact(id: "se006", region: "SE", category: .quirky, text: "\"Metallica\" rejected as baby name"),
        QuirkyFact(id: "se007", region: "SE", category: .tradition, text: "Fika: coffee breaks are sacred"),
        QuirkyFact(id: "se008", region: "SE", category: .tradition, text: "Lagom: not too much, not too little"),
        QuirkyFact(id: "se009", region: "SE", category: .quirky, text: "Empty bus seat? Never sit next to someone"),
        QuirkyFact(id: "se010", region: "SE", category: .quirky, text: "More believe in ghosts than God"),
        QuirkyFact(id: "se011", region: "SE", category: .quirky, text: "Cash is weird here. Cards only."),
        QuirkyFact(id: "se012", region: "SE", category: .tradition, text: "Oct 4: National Cinnamon Bun Day"),
        QuirkyFact(id: "se013", region: "SE", category: .tradition, text: "Mar 25: Waffle Day"),
        QuirkyFact(id: "se014", region: "SE", category: .nature, text: "First in Europe: national parks"),
        QuirkyFact(id: "se015", region: "SE", category: .nature, text: "Midnight sun: it never sets up north"),
        QuirkyFact(id: "se016", region: "SE", category: .invention, text: "Flat-pack furniture? Swedish idea."),
        QuirkyFact(id: "se017", region: "SE", category: .tradition, text: "Invisible queues. We just know."),
        QuirkyFact(id: "se018", region: "SE", category: .tradition, text: "Jantelagen: don't brag, ever"),
        QuirkyFact(id: "se019", region: "SE", category: .tradition, text: "Fredagsmys: cozy Fridays at home"),
        QuirkyFact(id: "se020", region: "SE", category: .tradition, text: "Shoes off indoors. Always."),
        QuirkyFact(id: "se021", region: "SE", category: .quirky, text: "\"Tack\" = please AND thank you"),
        QuirkyFact(id: "se022", region: "SE", category: .food, text: "Swedish coffee: strongest in Europe"),
        QuirkyFact(id: "se023", region: "SE", category: .tradition, text: "Lucia: candles in hair, Dec 13"),
        QuirkyFact(id: "se024", region: "SE", category: .tradition, text: "Kräftskiva: crayfish party in August"),
        QuirkyFact(id: "se025", region: "SE", category: .tradition, text: "Advent calendars have candy, not chocolate"),

        // Food & Drink
        QuirkyFact(id: "se026", region: "SE", category: .food, text: "Surströmming: world's smelliest food"),
        QuirkyFact(id: "se027", region: "SE", category: .food, text: "Julmust beats Coca-Cola in December"),
        QuirkyFact(id: "se028", region: "SE", category: .food, text: "Banana on pizza. Yes, really."),
        QuirkyFact(id: "se029", region: "SE", category: .food, text: "Kaviar comes in toothpaste tubes"),
        QuirkyFact(id: "se030", region: "SE", category: .food, text: "Princess cake is green (marzipan)"),
        QuirkyFact(id: "se031", region: "SE", category: .history, text: "A king died from eating too many semla"),
        QuirkyFact(id: "se032", region: "SE", category: .food, text: "Swedish meatballs: tiny and perfect"),
        QuirkyFact(id: "se033", region: "SE", category: .food, text: "Lingonberry jam on everything savory"),
        QuirkyFact(id: "se034", region: "SE", category: .food, text: "Filmjölk: sour milk for breakfast"),
        QuirkyFact(id: "se035", region: "SE", category: .food, text: "Crispbread lasts for years"),
        QuirkyFact(id: "se036", region: "SE", category: .food, text: "Highest candy consumption per capita"),
        QuirkyFact(id: "se037", region: "SE", category: .tradition, text: "Lördagsgodis: candy only on Saturdays"),
        QuirkyFact(id: "se038", region: "SE", category: .food, text: "Glögg: mulled wine with almonds"),
        QuirkyFact(id: "se039", region: "SE", category: .food, text: "Gravlax: salmon buried in sugar"),
        QuirkyFact(id: "se040", region: "SE", category: .food, text: "Toast Skagen: fancy shrimp toast"),
        QuirkyFact(id: "se041", region: "SE", category: .food, text: "Blood pudding: a school lunch classic"),
        QuirkyFact(id: "se042", region: "SE", category: .food, text: "Smörgåsbord = sandwich table"),
        QuirkyFact(id: "se043", region: "SE", category: .quirky, text: "Some dip cheese in coffee"),
        QuirkyFact(id: "se044", region: "SE", category: .food, text: "Tunnbrödsrulle: hot dog in flatbread"),
        QuirkyFact(id: "se045", region: "SE", category: .food, text: "Swedish pancakes are thin, like crêpes"),

        // Inventions & Innovation
        QuirkyFact(id: "se046", region: "SE", category: .invention, text: "Dynamite: Alfred Nobel, 1866"),
        QuirkyFact(id: "se047", region: "SE", category: .invention, text: "Three-point seatbelt: Volvo, 1959"),
        QuirkyFact(id: "se048", region: "SE", category: .invention, text: "Celsius scale: Anders Celsius"),
        QuirkyFact(id: "se049", region: "SE", category: .invention, text: "Pacemaker: invented here"),
        QuirkyFact(id: "se050", region: "SE", category: .invention, text: "Computer mouse: Swedish invention"),
        QuirkyFact(id: "se051", region: "SE", category: .invention, text: "Spotify: born in Stockholm"),
        QuirkyFact(id: "se052", region: "SE", category: .invention, text: "Skype: co-founded by a Swede"),
        QuirkyFact(id: "se053", region: "SE", category: .invention, text: "Tetra Pak changed packaging forever"),
        QuirkyFact(id: "se054", region: "SE", category: .invention, text: "Adjustable wrench: Swedish tool"),
        QuirkyFact(id: "se055", region: "SE", category: .invention, text: "IKEA: world's biggest furniture store"),
        QuirkyFact(id: "se056", region: "SE", category: .invention, text: "Bluetooth named after a Viking king"),
        QuirkyFact(id: "se057", region: "SE", category: .invention, text: "Zipper perfected by Gideon Sundbäck"),
        QuirkyFact(id: "se058", region: "SE", category: .invention, text: "Ball bearings: a Swedish invention"),
        QuirkyFact(id: "se059", region: "SE", category: .invention, text: "Linnaeus invented species naming"),
        QuirkyFact(id: "se060", region: "SE", category: .invention, text: "H&M: from small town to global"),
        QuirkyFact(id: "se061", region: "SE", category: .invention, text: "Safety matches: Swedish creation"),
        QuirkyFact(id: "se062", region: "SE", category: .invention, text: "Volvo means \"I roll\" in Latin"),
        QuirkyFact(id: "se063", region: "SE", category: .invention, text: "First ombudsman: Sweden, 1809"),
        QuirkyFact(id: "se064", region: "SE", category: .invention, text: "ABBA: 3rd largest music exporter"),
        QuirkyFact(id: "se065", region: "SE", category: .invention, text: "99% of waste gets recycled"),

        // Geography & Nature
        QuirkyFact(id: "se066", region: "SE", category: .nature, text: "69% forest coverage"),
        QuirkyFact(id: "se067", region: "SE", category: .nature, text: "100,000+ lakes"),
        QuirkyFact(id: "se068", region: "SE", category: .nature, text: "Stockholm: 14 islands"),
        QuirkyFact(id: "se069", region: "SE", category: .nature, text: "Kebnekaise: 2,100m peak"),
        QuirkyFact(id: "se070", region: "SE", category: .nature, text: "Vänern: Europe's 3rd largest lake"),
        QuirkyFact(id: "se071", region: "SE", category: .nature, text: "Gotland: biggest island"),
        QuirkyFact(id: "se072", region: "SE", category: .invention, text: "Öresund Bridge: to Denmark"),
        QuirkyFact(id: "se073", region: "SE", category: .nature, text: "29 national parks"),
        QuirkyFact(id: "se074", region: "SE", category: .nature, text: "Arctic fox: fewer than 200 left"),
        QuirkyFact(id: "se075", region: "SE", category: .nature, text: "Brown bears in the north"),
        QuirkyFact(id: "se076", region: "SE", category: .nature, text: "Northern Lights in Lapland"),
        QuirkyFact(id: "se077", region: "SE", category: .nature, text: "3rd largest EU country by area"),
        QuirkyFact(id: "se078", region: "SE", category: .nature, text: "Klarälven: Scandinavia's longest river"),
        QuirkyFact(id: "se079", region: "SE", category: .tradition, text: "Allemansrätten: right to roam"),
        QuirkyFact(id: "se080", region: "SE", category: .nature, text: "More moose than people in some areas"),
        QuirkyFact(id: "se081", region: "SE", category: .nature, text: "220,000+ islands"),
        QuirkyFact(id: "se082", region: "SE", category: .quirky, text: "Ice Hotel: rebuilt every winter"),
        QuirkyFact(id: "se083", region: "SE", category: .tradition, text: "Sami: indigenous reindeer herders"),
        QuirkyFact(id: "se084", region: "SE", category: .nature, text: "24 hours of summer daylight"),
        QuirkyFact(id: "se085", region: "SE", category: .nature, text: "Borders Norway and Finland"),

        // History & Quirky
        QuirkyFact(id: "se086", region: "SE", category: .history, text: "No war since 1814"),
        QuirkyFact(id: "se087", region: "SE", category: .history, text: "Vikings came from here"),
        QuirkyFact(id: "se088", region: "SE", category: .quirky, text: "North Korea owes us 1,000 Volvos"),
        QuirkyFact(id: "se089", region: "SE", category: .history, text: "European superpower in the 1600s"),
        QuirkyFact(id: "se090", region: "SE", category: .history, text: "Press freedom since 1766"),
        QuirkyFact(id: "se091", region: "SE", category: .history, text: "Sami: here before Sweden existed"),
        QuirkyFact(id: "se092", region: "SE", category: .invention, text: "Nobel Prize: Alfred's legacy"),
        QuirkyFact(id: "se093", region: "SE", category: .quirky, text: "Swedish passport: very powerful"),
        QuirkyFact(id: "se094", region: "SE", category: .history, text: "Skansen: world's first open-air museum"),
        QuirkyFact(id: "se095", region: "SE", category: .quirky, text: "Metro = world's longest art gallery"),
        QuirkyFact(id: "se096", region: "SE", category: .history, text: "Neutral in both World Wars"),
        QuirkyFact(id: "se097", region: "SE", category: .quirky, text: "Among the tallest people on Earth"),
        QuirkyFact(id: "se098", region: "SE", category: .quirky, text: "\"Smörgåsbord\" is now English"),
        QuirkyFact(id: "se099", region: "SE", category: .tradition, text: "Donald Duck on TV every Christmas Eve"),
        QuirkyFact(id: "se100", region: "SE", category: .quirky, text: "Swedes love silence. Embrace it."),
    ]

    // MARK: - Vietnamese Facts (Priority Region)

    static let vietnam: [QuirkyFact] = [
        QuirkyFact(id: "vn001", region: "VN", category: .food, text: "Egg coffee: cà phê trứng"),
        QuirkyFact(id: "vn002", region: "VN", category: .food, text: "Beer on ice. Always."),
        QuirkyFact(id: "vn003", region: "VN", category: .quirky, text: "40% are named Nguyen"),
        QuirkyFact(id: "vn004", region: "VN", category: .food, text: "World's 2nd largest coffee exporter"),
        QuirkyFact(id: "vn005", region: "VN", category: .quirky, text: "6 tones change word meaning entirely"),
        QuirkyFact(id: "vn006", region: "VN", category: .tradition, text: "Pyjamas are daytime clothes here"),
        QuirkyFact(id: "vn007", region: "VN", category: .food, text: "Phở and bánh mì: in the dictionary"),
        QuirkyFact(id: "vn008", region: "VN", category: .tradition, text: "Age question on first meeting: normal"),
        QuirkyFact(id: "vn009", region: "VN", category: .tradition, text: "Karaoke: passion over perfection"),
        QuirkyFact(id: "vn010", region: "VN", category: .food, text: "Condensed milk in everything"),
        QuirkyFact(id: "vn011", region: "VN", category: .quirky, text: "Love markets: speed dating since forever"),
        QuirkyFact(id: "vn012", region: "VN", category: .quirky, text: "Thin houses: 3 meters wide, 5 floors"),
        QuirkyFact(id: "vn013", region: "VN", category: .quirky, text: "Twin village: something in the water"),
        QuirkyFact(id: "vn014", region: "VN", category: .nature, text: "Ha Long Bay: 1,600 limestone islands"),
        QuirkyFact(id: "vn015", region: "VN", category: .history, text: "Nguyen dynasty ruled until 1945"),
        QuirkyFact(id: "vn016", region: "VN", category: .tradition, text: "Tết: most important holiday"),
        QuirkyFact(id: "vn017", region: "VN", category: .food, text: "Fish sauce: nước mắm in everything"),
        QuirkyFact(id: "vn018", region: "VN", category: .quirky, text: "Motorbike nation: 45 million+"),
        QuirkyFact(id: "vn019", region: "VN", category: .nature, text: "S-shaped country, 3,260km coastline"),
        QuirkyFact(id: "vn020", region: "VN", category: .tradition, text: "Ancestor worship is central"),
        QuirkyFact(id: "vn021", region: "VN", category: .food, text: "Bánh cuốn: steamed rice rolls"),
        QuirkyFact(id: "vn022", region: "VN", category: .quirky, text: "Honking = I'm here, not angry"),
        QuirkyFact(id: "vn023", region: "VN", category: .nature, text: "Son Doong: world's largest cave"),
        QuirkyFact(id: "vn024", region: "VN", category: .tradition, text: "Red and gold: lucky colors"),
        QuirkyFact(id: "vn025", region: "VN", category: .food, text: "Cơm tấm: broken rice, not a mistake"),
        QuirkyFact(id: "vn026", region: "VN", category: .history, text: "4,000 years of civilization"),
        QuirkyFact(id: "vn027", region: "VN", category: .tradition, text: "Full moon festival: mooncakes"),
        QuirkyFact(id: "vn028", region: "VN", category: .quirky, text: "Napping at work: totally normal"),
        QuirkyFact(id: "vn029", region: "VN", category: .nature, text: "Mekong Delta: rice bowl of Asia"),
        QuirkyFact(id: "vn030", region: "VN", category: .food, text: "Bia hơi: fresh beer, 25 cents"),
    ]

    // MARK: - UK Facts

    static let uk: [QuirkyFact] = [
        QuirkyFact(id: "uk001", region: "UK", category: .tradition, text: "100 million cups of tea daily"),
        QuirkyFact(id: "uk002", region: "UK", category: .tradition, text: "Queuing is sacred. Don't skip."),
        QuirkyFact(id: "uk003", region: "UK", category: .quirky, text: "Apologizing for being apologized to"),
        QuirkyFact(id: "uk004", region: "UK", category: .quirky, text: "Illegal to die in Parliament"),
        QuirkyFact(id: "uk005", region: "UK", category: .quirky, text: "No armor allowed in Parliament"),
        QuirkyFact(id: "uk006", region: "UK", category: .tradition, text: "Tower ravens: lose them, lose kingdom"),
        QuirkyFact(id: "uk007", region: "UK", category: .tradition, text: "Mayors get weighed: before and after"),
        QuirkyFact(id: "uk008", region: "UK", category: .quirky, text: "Cheese rolling: down a steep hill"),
        QuirkyFact(id: "uk009", region: "UK", category: .quirky, text: "Bog snorkelling championships exist"),
        QuirkyFact(id: "uk010", region: "UK", category: .quirky, text: "Gurning: ugliest face wins"),
        QuirkyFact(id: "uk011", region: "UK", category: .tradition, text: "Conker championships: since 1965"),
        QuirkyFact(id: "uk012", region: "UK", category: .tradition, text: "Up Helly Aa: Vikings burn a ship"),
        QuirkyFact(id: "uk013", region: "UK", category: .food, text: "Chicken tikka masala: national dish"),
        QuirkyFact(id: "uk014", region: "UK", category: .quirky, text: "Shortest flight: 47 seconds"),
        QuirkyFact(id: "uk015", region: "UK", category: .history, text: "Stonehenge: older than pyramids"),
        QuirkyFact(id: "uk016", region: "UK", category: .invention, text: "World Wide Web: Tim Berners-Lee"),
        QuirkyFact(id: "uk017", region: "UK", category: .quirky, text: "Big Ben is the bell, not the tower"),
        QuirkyFact(id: "uk018", region: "UK", category: .quirky, text: "Pensylvania on Liberty Bell: correct then"),
        QuirkyFact(id: "uk019", region: "UK", category: .tradition, text: "Turkey pardon: only since 1989"),
        QuirkyFact(id: "uk020", region: "UK", category: .nature, text: "UK has 30+ royal parks"),
        QuirkyFact(id: "uk021", region: "UK", category: .tradition, text: "Fish and chips: Friday tradition"),
        QuirkyFact(id: "uk022", region: "UK", category: .quirky, text: "Black cabs: drivers know every street"),
        QuirkyFact(id: "uk023", region: "UK", category: .invention, text: "First postage stamp: Penny Black"),
        QuirkyFact(id: "uk024", region: "UK", category: .tradition, text: "Bonfire Night: Nov 5"),
        QuirkyFact(id: "uk025", region: "UK", category: .quirky, text: "Driving on the left: Roman legacy"),
    ]

    // MARK: - US Facts

    static let us: [QuirkyFact] = [
        QuirkyFact(id: "us001", region: "US", category: .quirky, text: "No official national language"),
        QuirkyFact(id: "us002", region: "US", category: .history, text: "Flag redesigned 27 times"),
        QuirkyFact(id: "us003", region: "US", category: .quirky, text: "Alaska: 2 cents per acre from Russia"),
        QuirkyFact(id: "us004", region: "US", category: .nature, text: "Mauna Kea: taller than Everest (base)"),
        QuirkyFact(id: "us005", region: "US", category: .quirky, text: "Grizzly cubs lived at White House"),
        QuirkyFact(id: "us006", region: "US", category: .tradition, text: "Tipping: because wages are low"),
        QuirkyFact(id: "us007", region: "US", category: .history, text: "Code talkers: unbreakable encryption"),
        QuirkyFact(id: "us008", region: "US", category: .quirky, text: "Library of Congress: 470 languages"),
        QuirkyFact(id: "us009", region: "US", category: .nature, text: "Only place: crocs and gators together"),
        QuirkyFact(id: "us010", region: "US", category: .food, text: "10+ national food days"),
        QuirkyFact(id: "us011", region: "US", category: .quirky, text: "50 states, 50 stars"),
        QuirkyFact(id: "us012", region: "US", category: .tradition, text: "Baby showers: started in the 1950s"),
        QuirkyFact(id: "us013", region: "US", category: .nature, text: "Grand Canyon: 6 million years old"),
        QuirkyFact(id: "us014", region: "US", category: .invention, text: "Moon landing: July 20, 1969"),
        QuirkyFact(id: "us015", region: "US", category: .food, text: "Apple pie: not actually American"),
        QuirkyFact(id: "us016", region: "US", category: .quirky, text: "Every state has a weird law"),
        QuirkyFact(id: "us017", region: "US", category: .tradition, text: "Super Bowl: unofficial holiday"),
        QuirkyFact(id: "us018", region: "US", category: .history, text: "Fourth of July: wrong date anyway"),
        QuirkyFact(id: "us019", region: "US", category: .nature, text: "Yellowstone: first national park"),
        QuirkyFact(id: "us020", region: "US", category: .quirky, text: "One town is in two time zones"),
    ]

    // MARK: - Easter Eggs

    static let easterEggs: [QuirkyFact] = [
        QuirkyFact(id: "ee001", region: "XX", category: .quirky, text: "Nils Johansson: born Jan 30, 1983"),
        QuirkyFact(id: "ee002", region: "XX", category: .quirky, text: "Made with ❤️ in Sweden"),
        QuirkyFact(id: "ee003", region: "XX", category: .quirky, text: "情報デザイン: information design"),
        QuirkyFact(id: "ee004", region: "XX", category: .quirky, text: "Week numbers matter."),
        QuirkyFact(id: "ee005", region: "XX", category: .quirky, text: "Onsen: hot spring for the soul"),
    ]

    // MARK: - Access Methods

    /// Get all facts for a specific region
    static func facts(for region: String) -> [QuirkyFact] {
        switch region.uppercased() {
        case "SE": return sweden
        case "VN": return vietnam
        case "UK": return uk
        case "US": return us
        default: return []
        }
    }

    /// Get all facts from all regions
    static var allFacts: [QuirkyFact] {
        sweden + vietnam + uk + us
    }

    /// Get facts for multiple regions (priority order)
    static func facts(for regions: [String]) -> [QuirkyFact] {
        regions.flatMap { facts(for: $0) }
    }

    /// Total fact count
    static var totalCount: Int {
        sweden.count + vietnam.count + uk.count + us.count + easterEggs.count
    }
}
