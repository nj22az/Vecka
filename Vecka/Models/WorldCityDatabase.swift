//
//  WorldCityDatabase.swift
//  Vecka
//
//  情報デザイン: Comprehensive world city database for timezone lookup
//  Supports intelligent search by city name, country, or region
//

import Foundation

/// A world city with timezone information
struct WorldCity: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let country: String
    let countryCode: String  // ISO 3166-1 alpha-2
    let timezone: String     // IANA timezone identifier
    let code: String         // 3-letter city code
    let region: WorldRegion

    /// Search keywords (city + country + aliases)
    var searchKeywords: String {
        "\(name) \(country) \(countryCode) \(code)".lowercased()
    }
}

/// World regions for color theming (情報デザイン)
enum WorldRegion: String, CaseIterable {
    case europe = "Europe"
    case asia = "Asia"
    case northAmerica = "North America"
    case southAmerica = "South America"
    case africa = "Africa"
    case oceania = "Oceania"
    case middleEast = "Middle East"
}

/// Comprehensive world city database with intelligent search
struct WorldCityDatabase {

    // MARK: - Database

    /// All world cities (~500 entries covering major cities worldwide)
    static let cities: [WorldCity] = [
        // ═══════════════════════════════════════════════════════════════
        // EUROPE
        // ═══════════════════════════════════════════════════════════════

        // Scandinavia
        WorldCity(name: "Stora Mellösa", country: "Sweden", countryCode: "SE", timezone: "Europe/Stockholm", code: "STM", region: .europe),
        WorldCity(name: "Stockholm", country: "Sweden", countryCode: "SE", timezone: "Europe/Stockholm", code: "ARN", region: .europe),
        WorldCity(name: "Gothenburg", country: "Sweden", countryCode: "SE", timezone: "Europe/Stockholm", code: "GOT", region: .europe),
        WorldCity(name: "Malmö", country: "Sweden", countryCode: "SE", timezone: "Europe/Stockholm", code: "MMA", region: .europe),
        WorldCity(name: "Uppsala", country: "Sweden", countryCode: "SE", timezone: "Europe/Stockholm", code: "UPP", region: .europe),
        WorldCity(name: "Örebro", country: "Sweden", countryCode: "SE", timezone: "Europe/Stockholm", code: "ORB", region: .europe),
        WorldCity(name: "Linköping", country: "Sweden", countryCode: "SE", timezone: "Europe/Stockholm", code: "LNK", region: .europe),
        WorldCity(name: "Oslo", country: "Norway", countryCode: "NO", timezone: "Europe/Oslo", code: "OSL", region: .europe),
        WorldCity(name: "Bergen", country: "Norway", countryCode: "NO", timezone: "Europe/Oslo", code: "BGO", region: .europe),
        WorldCity(name: "Trondheim", country: "Norway", countryCode: "NO", timezone: "Europe/Oslo", code: "TRD", region: .europe),
        WorldCity(name: "Copenhagen", country: "Denmark", countryCode: "DK", timezone: "Europe/Copenhagen", code: "CPH", region: .europe),
        WorldCity(name: "Aarhus", country: "Denmark", countryCode: "DK", timezone: "Europe/Copenhagen", code: "AAR", region: .europe),
        WorldCity(name: "Helsinki", country: "Finland", countryCode: "FI", timezone: "Europe/Helsinki", code: "HEL", region: .europe),
        WorldCity(name: "Tampere", country: "Finland", countryCode: "FI", timezone: "Europe/Helsinki", code: "TMP", region: .europe),
        WorldCity(name: "Reykjavik", country: "Iceland", countryCode: "IS", timezone: "Atlantic/Reykjavik", code: "REK", region: .europe),

        // Western Europe
        WorldCity(name: "London", country: "United Kingdom", countryCode: "GB", timezone: "Europe/London", code: "LON", region: .europe),
        WorldCity(name: "Manchester", country: "United Kingdom", countryCode: "GB", timezone: "Europe/London", code: "MAN", region: .europe),
        WorldCity(name: "Birmingham", country: "United Kingdom", countryCode: "GB", timezone: "Europe/London", code: "BHX", region: .europe),
        WorldCity(name: "Edinburgh", country: "United Kingdom", countryCode: "GB", timezone: "Europe/London", code: "EDI", region: .europe),
        WorldCity(name: "Glasgow", country: "United Kingdom", countryCode: "GB", timezone: "Europe/London", code: "GLA", region: .europe),
        WorldCity(name: "Dublin", country: "Ireland", countryCode: "IE", timezone: "Europe/Dublin", code: "DUB", region: .europe),
        WorldCity(name: "Paris", country: "France", countryCode: "FR", timezone: "Europe/Paris", code: "PAR", region: .europe),
        WorldCity(name: "Lyon", country: "France", countryCode: "FR", timezone: "Europe/Paris", code: "LYS", region: .europe),
        WorldCity(name: "Marseille", country: "France", countryCode: "FR", timezone: "Europe/Paris", code: "MRS", region: .europe),
        WorldCity(name: "Nice", country: "France", countryCode: "FR", timezone: "Europe/Paris", code: "NCE", region: .europe),
        WorldCity(name: "Bordeaux", country: "France", countryCode: "FR", timezone: "Europe/Paris", code: "BOD", region: .europe),
        WorldCity(name: "Amsterdam", country: "Netherlands", countryCode: "NL", timezone: "Europe/Amsterdam", code: "AMS", region: .europe),
        WorldCity(name: "Rotterdam", country: "Netherlands", countryCode: "NL", timezone: "Europe/Amsterdam", code: "RTM", region: .europe),
        WorldCity(name: "Brussels", country: "Belgium", countryCode: "BE", timezone: "Europe/Brussels", code: "BRU", region: .europe),
        WorldCity(name: "Antwerp", country: "Belgium", countryCode: "BE", timezone: "Europe/Brussels", code: "ANR", region: .europe),
        WorldCity(name: "Luxembourg", country: "Luxembourg", countryCode: "LU", timezone: "Europe/Luxembourg", code: "LUX", region: .europe),

        // Central Europe
        WorldCity(name: "Berlin", country: "Germany", countryCode: "DE", timezone: "Europe/Berlin", code: "BER", region: .europe),
        WorldCity(name: "Munich", country: "Germany", countryCode: "DE", timezone: "Europe/Berlin", code: "MUC", region: .europe),
        WorldCity(name: "Frankfurt", country: "Germany", countryCode: "DE", timezone: "Europe/Berlin", code: "FRA", region: .europe),
        WorldCity(name: "Hamburg", country: "Germany", countryCode: "DE", timezone: "Europe/Berlin", code: "HAM", region: .europe),
        WorldCity(name: "Cologne", country: "Germany", countryCode: "DE", timezone: "Europe/Berlin", code: "CGN", region: .europe),
        WorldCity(name: "Düsseldorf", country: "Germany", countryCode: "DE", timezone: "Europe/Berlin", code: "DUS", region: .europe),
        WorldCity(name: "Stuttgart", country: "Germany", countryCode: "DE", timezone: "Europe/Berlin", code: "STR", region: .europe),
        WorldCity(name: "Vienna", country: "Austria", countryCode: "AT", timezone: "Europe/Vienna", code: "VIE", region: .europe),
        WorldCity(name: "Salzburg", country: "Austria", countryCode: "AT", timezone: "Europe/Vienna", code: "SZG", region: .europe),
        WorldCity(name: "Zurich", country: "Switzerland", countryCode: "CH", timezone: "Europe/Zurich", code: "ZRH", region: .europe),
        WorldCity(name: "Geneva", country: "Switzerland", countryCode: "CH", timezone: "Europe/Zurich", code: "GVA", region: .europe),
        WorldCity(name: "Bern", country: "Switzerland", countryCode: "CH", timezone: "Europe/Zurich", code: "BRN", region: .europe),
        WorldCity(name: "Prague", country: "Czech Republic", countryCode: "CZ", timezone: "Europe/Prague", code: "PRG", region: .europe),
        WorldCity(name: "Warsaw", country: "Poland", countryCode: "PL", timezone: "Europe/Warsaw", code: "WAW", region: .europe),
        WorldCity(name: "Krakow", country: "Poland", countryCode: "PL", timezone: "Europe/Warsaw", code: "KRK", region: .europe),
        WorldCity(name: "Budapest", country: "Hungary", countryCode: "HU", timezone: "Europe/Budapest", code: "BUD", region: .europe),
        WorldCity(name: "Bratislava", country: "Slovakia", countryCode: "SK", timezone: "Europe/Bratislava", code: "BTS", region: .europe),

        // Southern Europe
        WorldCity(name: "Rome", country: "Italy", countryCode: "IT", timezone: "Europe/Rome", code: "ROM", region: .europe),
        WorldCity(name: "Milan", country: "Italy", countryCode: "IT", timezone: "Europe/Rome", code: "MIL", region: .europe),
        WorldCity(name: "Venice", country: "Italy", countryCode: "IT", timezone: "Europe/Rome", code: "VCE", region: .europe),
        WorldCity(name: "Florence", country: "Italy", countryCode: "IT", timezone: "Europe/Rome", code: "FLR", region: .europe),
        WorldCity(name: "Naples", country: "Italy", countryCode: "IT", timezone: "Europe/Rome", code: "NAP", region: .europe),
        WorldCity(name: "Madrid", country: "Spain", countryCode: "ES", timezone: "Europe/Madrid", code: "MAD", region: .europe),
        WorldCity(name: "Barcelona", country: "Spain", countryCode: "ES", timezone: "Europe/Madrid", code: "BCN", region: .europe),
        WorldCity(name: "Valencia", country: "Spain", countryCode: "ES", timezone: "Europe/Madrid", code: "VLC", region: .europe),
        WorldCity(name: "Seville", country: "Spain", countryCode: "ES", timezone: "Europe/Madrid", code: "SVQ", region: .europe),
        WorldCity(name: "Lisbon", country: "Portugal", countryCode: "PT", timezone: "Europe/Lisbon", code: "LIS", region: .europe),
        WorldCity(name: "Porto", country: "Portugal", countryCode: "PT", timezone: "Europe/Lisbon", code: "OPO", region: .europe),
        WorldCity(name: "Athens", country: "Greece", countryCode: "GR", timezone: "Europe/Athens", code: "ATH", region: .europe),
        WorldCity(name: "Thessaloniki", country: "Greece", countryCode: "GR", timezone: "Europe/Athens", code: "SKG", region: .europe),

        // Eastern Europe
        WorldCity(name: "Moscow", country: "Russia", countryCode: "RU", timezone: "Europe/Moscow", code: "MOW", region: .europe),
        WorldCity(name: "Saint Petersburg", country: "Russia", countryCode: "RU", timezone: "Europe/Moscow", code: "LED", region: .europe),
        WorldCity(name: "Kyiv", country: "Ukraine", countryCode: "UA", timezone: "Europe/Kyiv", code: "KBP", region: .europe),
        WorldCity(name: "Bucharest", country: "Romania", countryCode: "RO", timezone: "Europe/Bucharest", code: "BUH", region: .europe),
        WorldCity(name: "Sofia", country: "Bulgaria", countryCode: "BG", timezone: "Europe/Sofia", code: "SOF", region: .europe),
        WorldCity(name: "Belgrade", country: "Serbia", countryCode: "RS", timezone: "Europe/Belgrade", code: "BEG", region: .europe),
        WorldCity(name: "Zagreb", country: "Croatia", countryCode: "HR", timezone: "Europe/Zagreb", code: "ZAG", region: .europe),
        WorldCity(name: "Ljubljana", country: "Slovenia", countryCode: "SI", timezone: "Europe/Ljubljana", code: "LJU", region: .europe),
        WorldCity(name: "Tallinn", country: "Estonia", countryCode: "EE", timezone: "Europe/Tallinn", code: "TLL", region: .europe),
        WorldCity(name: "Riga", country: "Latvia", countryCode: "LV", timezone: "Europe/Riga", code: "RIX", region: .europe),
        WorldCity(name: "Vilnius", country: "Lithuania", countryCode: "LT", timezone: "Europe/Vilnius", code: "VNO", region: .europe),

        // ═══════════════════════════════════════════════════════════════
        // ASIA
        // ═══════════════════════════════════════════════════════════════

        // East Asia
        WorldCity(name: "Tokyo", country: "Japan", countryCode: "JP", timezone: "Asia/Tokyo", code: "TYO", region: .asia),
        WorldCity(name: "Osaka", country: "Japan", countryCode: "JP", timezone: "Asia/Tokyo", code: "OSA", region: .asia),
        WorldCity(name: "Kyoto", country: "Japan", countryCode: "JP", timezone: "Asia/Tokyo", code: "KYO", region: .asia),
        WorldCity(name: "Nagoya", country: "Japan", countryCode: "JP", timezone: "Asia/Tokyo", code: "NGO", region: .asia),
        WorldCity(name: "Sapporo", country: "Japan", countryCode: "JP", timezone: "Asia/Tokyo", code: "SPK", region: .asia),
        WorldCity(name: "Fukuoka", country: "Japan", countryCode: "JP", timezone: "Asia/Tokyo", code: "FUK", region: .asia),
        WorldCity(name: "Seoul", country: "South Korea", countryCode: "KR", timezone: "Asia/Seoul", code: "SEL", region: .asia),
        WorldCity(name: "Busan", country: "South Korea", countryCode: "KR", timezone: "Asia/Seoul", code: "PUS", region: .asia),
        WorldCity(name: "Beijing", country: "China", countryCode: "CN", timezone: "Asia/Shanghai", code: "PEK", region: .asia),
        WorldCity(name: "Shanghai", country: "China", countryCode: "CN", timezone: "Asia/Shanghai", code: "SHA", region: .asia),
        WorldCity(name: "Guangzhou", country: "China", countryCode: "CN", timezone: "Asia/Shanghai", code: "CAN", region: .asia),
        WorldCity(name: "Shenzhen", country: "China", countryCode: "CN", timezone: "Asia/Shanghai", code: "SZX", region: .asia),
        WorldCity(name: "Chengdu", country: "China", countryCode: "CN", timezone: "Asia/Shanghai", code: "CTU", region: .asia),
        WorldCity(name: "Hangzhou", country: "China", countryCode: "CN", timezone: "Asia/Shanghai", code: "HGH", region: .asia),
        WorldCity(name: "Hong Kong", country: "Hong Kong", countryCode: "HK", timezone: "Asia/Hong_Kong", code: "HKG", region: .asia),
        WorldCity(name: "Taipei", country: "Taiwan", countryCode: "TW", timezone: "Asia/Taipei", code: "TPE", region: .asia),
        WorldCity(name: "Macau", country: "Macau", countryCode: "MO", timezone: "Asia/Macau", code: "MFM", region: .asia),
        WorldCity(name: "Ulaanbaatar", country: "Mongolia", countryCode: "MN", timezone: "Asia/Ulaanbaatar", code: "ULN", region: .asia),

        // Southeast Asia
        WorldCity(name: "Singapore", country: "Singapore", countryCode: "SG", timezone: "Asia/Singapore", code: "SIN", region: .asia),
        WorldCity(name: "Bangkok", country: "Thailand", countryCode: "TH", timezone: "Asia/Bangkok", code: "BKK", region: .asia),
        WorldCity(name: "Chiang Mai", country: "Thailand", countryCode: "TH", timezone: "Asia/Bangkok", code: "CNX", region: .asia),
        WorldCity(name: "Phuket", country: "Thailand", countryCode: "TH", timezone: "Asia/Bangkok", code: "HKT", region: .asia),
        WorldCity(name: "Ho Chi Minh City", country: "Vietnam", countryCode: "VN", timezone: "Asia/Ho_Chi_Minh", code: "SGN", region: .asia),
        WorldCity(name: "Hanoi", country: "Vietnam", countryCode: "VN", timezone: "Asia/Ho_Chi_Minh", code: "HAN", region: .asia),
        WorldCity(name: "Da Nang", country: "Vietnam", countryCode: "VN", timezone: "Asia/Ho_Chi_Minh", code: "DAD", region: .asia),
        WorldCity(name: "Kuala Lumpur", country: "Malaysia", countryCode: "MY", timezone: "Asia/Kuala_Lumpur", code: "KUL", region: .asia),
        WorldCity(name: "Penang", country: "Malaysia", countryCode: "MY", timezone: "Asia/Kuala_Lumpur", code: "PEN", region: .asia),
        WorldCity(name: "Jakarta", country: "Indonesia", countryCode: "ID", timezone: "Asia/Jakarta", code: "JKT", region: .asia),
        WorldCity(name: "Bali", country: "Indonesia", countryCode: "ID", timezone: "Asia/Makassar", code: "DPS", region: .asia),
        WorldCity(name: "Surabaya", country: "Indonesia", countryCode: "ID", timezone: "Asia/Jakarta", code: "SUB", region: .asia),
        WorldCity(name: "Manila", country: "Philippines", countryCode: "PH", timezone: "Asia/Manila", code: "MNL", region: .asia),
        WorldCity(name: "Cebu", country: "Philippines", countryCode: "PH", timezone: "Asia/Manila", code: "CEB", region: .asia),
        WorldCity(name: "Phnom Penh", country: "Cambodia", countryCode: "KH", timezone: "Asia/Phnom_Penh", code: "PNH", region: .asia),
        WorldCity(name: "Vientiane", country: "Laos", countryCode: "LA", timezone: "Asia/Vientiane", code: "VTE", region: .asia),
        WorldCity(name: "Yangon", country: "Myanmar", countryCode: "MM", timezone: "Asia/Yangon", code: "RGN", region: .asia),
        WorldCity(name: "Brunei", country: "Brunei", countryCode: "BN", timezone: "Asia/Brunei", code: "BWN", region: .asia),

        // South Asia
        WorldCity(name: "Mumbai", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "BOM", region: .asia),
        WorldCity(name: "Delhi", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "DEL", region: .asia),
        WorldCity(name: "Bangalore", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "BLR", region: .asia),
        WorldCity(name: "Chennai", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "MAA", region: .asia),
        WorldCity(name: "Kolkata", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "CCU", region: .asia),
        WorldCity(name: "Hyderabad", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "HYD", region: .asia),
        WorldCity(name: "Goa", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "GOI", region: .asia),
        WorldCity(name: "Jaipur", country: "India", countryCode: "IN", timezone: "Asia/Kolkata", code: "JAI", region: .asia),
        WorldCity(name: "Dhaka", country: "Bangladesh", countryCode: "BD", timezone: "Asia/Dhaka", code: "DAC", region: .asia),
        WorldCity(name: "Colombo", country: "Sri Lanka", countryCode: "LK", timezone: "Asia/Colombo", code: "CMB", region: .asia),
        WorldCity(name: "Kathmandu", country: "Nepal", countryCode: "NP", timezone: "Asia/Kathmandu", code: "KTM", region: .asia),
        WorldCity(name: "Karachi", country: "Pakistan", countryCode: "PK", timezone: "Asia/Karachi", code: "KHI", region: .asia),
        WorldCity(name: "Lahore", country: "Pakistan", countryCode: "PK", timezone: "Asia/Karachi", code: "LHE", region: .asia),
        WorldCity(name: "Islamabad", country: "Pakistan", countryCode: "PK", timezone: "Asia/Karachi", code: "ISB", region: .asia),
        WorldCity(name: "Thimphu", country: "Bhutan", countryCode: "BT", timezone: "Asia/Thimphu", code: "PBH", region: .asia),
        WorldCity(name: "Male", country: "Maldives", countryCode: "MV", timezone: "Indian/Maldives", code: "MLE", region: .asia),

        // ═══════════════════════════════════════════════════════════════
        // MIDDLE EAST
        // ═══════════════════════════════════════════════════════════════

        WorldCity(name: "Dubai", country: "United Arab Emirates", countryCode: "AE", timezone: "Asia/Dubai", code: "DXB", region: .middleEast),
        WorldCity(name: "Abu Dhabi", country: "United Arab Emirates", countryCode: "AE", timezone: "Asia/Dubai", code: "AUH", region: .middleEast),
        WorldCity(name: "Doha", country: "Qatar", countryCode: "QA", timezone: "Asia/Qatar", code: "DOH", region: .middleEast),
        WorldCity(name: "Riyadh", country: "Saudi Arabia", countryCode: "SA", timezone: "Asia/Riyadh", code: "RUH", region: .middleEast),
        WorldCity(name: "Jeddah", country: "Saudi Arabia", countryCode: "SA", timezone: "Asia/Riyadh", code: "JED", region: .middleEast),
        WorldCity(name: "Mecca", country: "Saudi Arabia", countryCode: "SA", timezone: "Asia/Riyadh", code: "MEC", region: .middleEast),
        WorldCity(name: "Kuwait City", country: "Kuwait", countryCode: "KW", timezone: "Asia/Kuwait", code: "KWI", region: .middleEast),
        WorldCity(name: "Manama", country: "Bahrain", countryCode: "BH", timezone: "Asia/Bahrain", code: "BAH", region: .middleEast),
        WorldCity(name: "Muscat", country: "Oman", countryCode: "OM", timezone: "Asia/Muscat", code: "MCT", region: .middleEast),
        WorldCity(name: "Tel Aviv", country: "Israel", countryCode: "IL", timezone: "Asia/Jerusalem", code: "TLV", region: .middleEast),
        WorldCity(name: "Jerusalem", country: "Israel", countryCode: "IL", timezone: "Asia/Jerusalem", code: "JRS", region: .middleEast),
        WorldCity(name: "Amman", country: "Jordan", countryCode: "JO", timezone: "Asia/Amman", code: "AMM", region: .middleEast),
        WorldCity(name: "Beirut", country: "Lebanon", countryCode: "LB", timezone: "Asia/Beirut", code: "BEY", region: .middleEast),
        WorldCity(name: "Istanbul", country: "Turkey", countryCode: "TR", timezone: "Europe/Istanbul", code: "IST", region: .middleEast),
        WorldCity(name: "Ankara", country: "Turkey", countryCode: "TR", timezone: "Europe/Istanbul", code: "ANK", region: .middleEast),
        WorldCity(name: "Izmir", country: "Turkey", countryCode: "TR", timezone: "Europe/Istanbul", code: "ADB", region: .middleEast),
        WorldCity(name: "Tehran", country: "Iran", countryCode: "IR", timezone: "Asia/Tehran", code: "THR", region: .middleEast),
        WorldCity(name: "Baghdad", country: "Iraq", countryCode: "IQ", timezone: "Asia/Baghdad", code: "BGW", region: .middleEast),
        WorldCity(name: "Damascus", country: "Syria", countryCode: "SY", timezone: "Asia/Damascus", code: "DAM", region: .middleEast),
        WorldCity(name: "Baku", country: "Azerbaijan", countryCode: "AZ", timezone: "Asia/Baku", code: "GYD", region: .middleEast),
        WorldCity(name: "Tbilisi", country: "Georgia", countryCode: "GE", timezone: "Asia/Tbilisi", code: "TBS", region: .middleEast),
        WorldCity(name: "Yerevan", country: "Armenia", countryCode: "AM", timezone: "Asia/Yerevan", code: "EVN", region: .middleEast),

        // ═══════════════════════════════════════════════════════════════
        // NORTH AMERICA
        // ═══════════════════════════════════════════════════════════════

        // USA - East
        WorldCity(name: "New York", country: "United States", countryCode: "US", timezone: "America/New_York", code: "NYC", region: .northAmerica),
        WorldCity(name: "Boston", country: "United States", countryCode: "US", timezone: "America/New_York", code: "BOS", region: .northAmerica),
        WorldCity(name: "Philadelphia", country: "United States", countryCode: "US", timezone: "America/New_York", code: "PHL", region: .northAmerica),
        WorldCity(name: "Washington DC", country: "United States", countryCode: "US", timezone: "America/New_York", code: "DCA", region: .northAmerica),
        WorldCity(name: "Miami", country: "United States", countryCode: "US", timezone: "America/New_York", code: "MIA", region: .northAmerica),
        WorldCity(name: "Atlanta", country: "United States", countryCode: "US", timezone: "America/New_York", code: "ATL", region: .northAmerica),
        WorldCity(name: "Charlotte", country: "United States", countryCode: "US", timezone: "America/New_York", code: "CLT", region: .northAmerica),
        WorldCity(name: "Detroit", country: "United States", countryCode: "US", timezone: "America/Detroit", code: "DTW", region: .northAmerica),

        // USA - Central
        WorldCity(name: "Chicago", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "CHI", region: .northAmerica),
        WorldCity(name: "Houston", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "HOU", region: .northAmerica),
        WorldCity(name: "Dallas", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "DFW", region: .northAmerica),
        WorldCity(name: "Austin", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "AUS", region: .northAmerica),
        WorldCity(name: "San Antonio", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "SAT", region: .northAmerica),
        WorldCity(name: "Minneapolis", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "MSP", region: .northAmerica),
        WorldCity(name: "New Orleans", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "MSY", region: .northAmerica),
        WorldCity(name: "Nashville", country: "United States", countryCode: "US", timezone: "America/Chicago", code: "BNA", region: .northAmerica),

        // USA - Mountain
        WorldCity(name: "Denver", country: "United States", countryCode: "US", timezone: "America/Denver", code: "DEN", region: .northAmerica),
        WorldCity(name: "Phoenix", country: "United States", countryCode: "US", timezone: "America/Phoenix", code: "PHX", region: .northAmerica),
        WorldCity(name: "Salt Lake City", country: "United States", countryCode: "US", timezone: "America/Denver", code: "SLC", region: .northAmerica),
        WorldCity(name: "Las Vegas", country: "United States", countryCode: "US", timezone: "America/Los_Angeles", code: "LAS", region: .northAmerica),
        WorldCity(name: "Albuquerque", country: "United States", countryCode: "US", timezone: "America/Denver", code: "ABQ", region: .northAmerica),

        // USA - Pacific
        WorldCity(name: "Los Angeles", country: "United States", countryCode: "US", timezone: "America/Los_Angeles", code: "LAX", region: .northAmerica),
        WorldCity(name: "San Francisco", country: "United States", countryCode: "US", timezone: "America/Los_Angeles", code: "SFO", region: .northAmerica),
        WorldCity(name: "San Diego", country: "United States", countryCode: "US", timezone: "America/Los_Angeles", code: "SAN", region: .northAmerica),
        WorldCity(name: "Seattle", country: "United States", countryCode: "US", timezone: "America/Los_Angeles", code: "SEA", region: .northAmerica),
        WorldCity(name: "Portland", country: "United States", countryCode: "US", timezone: "America/Los_Angeles", code: "PDX", region: .northAmerica),
        WorldCity(name: "San Jose", country: "United States", countryCode: "US", timezone: "America/Los_Angeles", code: "SJC", region: .northAmerica),

        // USA - Other
        WorldCity(name: "Honolulu", country: "United States", countryCode: "US", timezone: "Pacific/Honolulu", code: "HNL", region: .northAmerica),
        WorldCity(name: "Anchorage", country: "United States", countryCode: "US", timezone: "America/Anchorage", code: "ANC", region: .northAmerica),

        // Canada
        WorldCity(name: "Toronto", country: "Canada", countryCode: "CA", timezone: "America/Toronto", code: "YYZ", region: .northAmerica),
        WorldCity(name: "Vancouver", country: "Canada", countryCode: "CA", timezone: "America/Vancouver", code: "YVR", region: .northAmerica),
        WorldCity(name: "Montreal", country: "Canada", countryCode: "CA", timezone: "America/Toronto", code: "YUL", region: .northAmerica),
        WorldCity(name: "Calgary", country: "Canada", countryCode: "CA", timezone: "America/Edmonton", code: "YYC", region: .northAmerica),
        WorldCity(name: "Edmonton", country: "Canada", countryCode: "CA", timezone: "America/Edmonton", code: "YEG", region: .northAmerica),
        WorldCity(name: "Ottawa", country: "Canada", countryCode: "CA", timezone: "America/Toronto", code: "YOW", region: .northAmerica),
        WorldCity(name: "Quebec City", country: "Canada", countryCode: "CA", timezone: "America/Toronto", code: "YQB", region: .northAmerica),
        WorldCity(name: "Winnipeg", country: "Canada", countryCode: "CA", timezone: "America/Winnipeg", code: "YWG", region: .northAmerica),
        WorldCity(name: "Halifax", country: "Canada", countryCode: "CA", timezone: "America/Halifax", code: "YHZ", region: .northAmerica),

        // Mexico & Central America
        WorldCity(name: "Mexico City", country: "Mexico", countryCode: "MX", timezone: "America/Mexico_City", code: "MEX", region: .northAmerica),
        WorldCity(name: "Cancun", country: "Mexico", countryCode: "MX", timezone: "America/Cancun", code: "CUN", region: .northAmerica),
        WorldCity(name: "Guadalajara", country: "Mexico", countryCode: "MX", timezone: "America/Mexico_City", code: "GDL", region: .northAmerica),
        WorldCity(name: "Monterrey", country: "Mexico", countryCode: "MX", timezone: "America/Monterrey", code: "MTY", region: .northAmerica),
        WorldCity(name: "Tijuana", country: "Mexico", countryCode: "MX", timezone: "America/Tijuana", code: "TIJ", region: .northAmerica),
        WorldCity(name: "Guatemala City", country: "Guatemala", countryCode: "GT", timezone: "America/Guatemala", code: "GUA", region: .northAmerica),
        WorldCity(name: "San Salvador", country: "El Salvador", countryCode: "SV", timezone: "America/El_Salvador", code: "SAL", region: .northAmerica),
        WorldCity(name: "Panama City", country: "Panama", countryCode: "PA", timezone: "America/Panama", code: "PTY", region: .northAmerica),
        WorldCity(name: "San Jose", country: "Costa Rica", countryCode: "CR", timezone: "America/Costa_Rica", code: "SJO", region: .northAmerica),
        WorldCity(name: "Havana", country: "Cuba", countryCode: "CU", timezone: "America/Havana", code: "HAV", region: .northAmerica),
        WorldCity(name: "Kingston", country: "Jamaica", countryCode: "JM", timezone: "America/Jamaica", code: "KIN", region: .northAmerica),
        WorldCity(name: "Nassau", country: "Bahamas", countryCode: "BS", timezone: "America/Nassau", code: "NAS", region: .northAmerica),
        WorldCity(name: "Santo Domingo", country: "Dominican Republic", countryCode: "DO", timezone: "America/Santo_Domingo", code: "SDQ", region: .northAmerica),
        WorldCity(name: "San Juan", country: "Puerto Rico", countryCode: "PR", timezone: "America/Puerto_Rico", code: "SJU", region: .northAmerica),

        // ═══════════════════════════════════════════════════════════════
        // SOUTH AMERICA
        // ═══════════════════════════════════════════════════════════════

        WorldCity(name: "São Paulo", country: "Brazil", countryCode: "BR", timezone: "America/Sao_Paulo", code: "GRU", region: .southAmerica),
        WorldCity(name: "Rio de Janeiro", country: "Brazil", countryCode: "BR", timezone: "America/Sao_Paulo", code: "GIG", region: .southAmerica),
        WorldCity(name: "Brasília", country: "Brazil", countryCode: "BR", timezone: "America/Sao_Paulo", code: "BSB", region: .southAmerica),
        WorldCity(name: "Salvador", country: "Brazil", countryCode: "BR", timezone: "America/Bahia", code: "SSA", region: .southAmerica),
        WorldCity(name: "Fortaleza", country: "Brazil", countryCode: "BR", timezone: "America/Fortaleza", code: "FOR", region: .southAmerica),
        WorldCity(name: "Buenos Aires", country: "Argentina", countryCode: "AR", timezone: "America/Argentina/Buenos_Aires", code: "EZE", region: .southAmerica),
        WorldCity(name: "Córdoba", country: "Argentina", countryCode: "AR", timezone: "America/Argentina/Cordoba", code: "COR", region: .southAmerica),
        WorldCity(name: "Mendoza", country: "Argentina", countryCode: "AR", timezone: "America/Argentina/Mendoza", code: "MDZ", region: .southAmerica),
        WorldCity(name: "Santiago", country: "Chile", countryCode: "CL", timezone: "America/Santiago", code: "SCL", region: .southAmerica),
        WorldCity(name: "Valparaíso", country: "Chile", countryCode: "CL", timezone: "America/Santiago", code: "VAP", region: .southAmerica),
        WorldCity(name: "Lima", country: "Peru", countryCode: "PE", timezone: "America/Lima", code: "LIM", region: .southAmerica),
        WorldCity(name: "Cusco", country: "Peru", countryCode: "PE", timezone: "America/Lima", code: "CUZ", region: .southAmerica),
        WorldCity(name: "Bogotá", country: "Colombia", countryCode: "CO", timezone: "America/Bogota", code: "BOG", region: .southAmerica),
        WorldCity(name: "Medellín", country: "Colombia", countryCode: "CO", timezone: "America/Bogota", code: "MDE", region: .southAmerica),
        WorldCity(name: "Cartagena", country: "Colombia", countryCode: "CO", timezone: "America/Bogota", code: "CTG", region: .southAmerica),
        WorldCity(name: "Caracas", country: "Venezuela", countryCode: "VE", timezone: "America/Caracas", code: "CCS", region: .southAmerica),
        WorldCity(name: "Quito", country: "Ecuador", countryCode: "EC", timezone: "America/Guayaquil", code: "UIO", region: .southAmerica),
        WorldCity(name: "Guayaquil", country: "Ecuador", countryCode: "EC", timezone: "America/Guayaquil", code: "GYE", region: .southAmerica),
        WorldCity(name: "La Paz", country: "Bolivia", countryCode: "BO", timezone: "America/La_Paz", code: "LPB", region: .southAmerica),
        WorldCity(name: "Montevideo", country: "Uruguay", countryCode: "UY", timezone: "America/Montevideo", code: "MVD", region: .southAmerica),
        WorldCity(name: "Asunción", country: "Paraguay", countryCode: "PY", timezone: "America/Asuncion", code: "ASU", region: .southAmerica),
        WorldCity(name: "Georgetown", country: "Guyana", countryCode: "GY", timezone: "America/Guyana", code: "GEO", region: .southAmerica),
        WorldCity(name: "Paramaribo", country: "Suriname", countryCode: "SR", timezone: "America/Paramaribo", code: "PBM", region: .southAmerica),

        // ═══════════════════════════════════════════════════════════════
        // AFRICA
        // ═══════════════════════════════════════════════════════════════

        // North Africa
        WorldCity(name: "Cairo", country: "Egypt", countryCode: "EG", timezone: "Africa/Cairo", code: "CAI", region: .africa),
        WorldCity(name: "Alexandria", country: "Egypt", countryCode: "EG", timezone: "Africa/Cairo", code: "ALY", region: .africa),
        WorldCity(name: "Casablanca", country: "Morocco", countryCode: "MA", timezone: "Africa/Casablanca", code: "CMN", region: .africa),
        WorldCity(name: "Marrakech", country: "Morocco", countryCode: "MA", timezone: "Africa/Casablanca", code: "RAK", region: .africa),
        WorldCity(name: "Tunis", country: "Tunisia", countryCode: "TN", timezone: "Africa/Tunis", code: "TUN", region: .africa),
        WorldCity(name: "Algiers", country: "Algeria", countryCode: "DZ", timezone: "Africa/Algiers", code: "ALG", region: .africa),
        WorldCity(name: "Tripoli", country: "Libya", countryCode: "LY", timezone: "Africa/Tripoli", code: "TIP", region: .africa),

        // West Africa
        WorldCity(name: "Lagos", country: "Nigeria", countryCode: "NG", timezone: "Africa/Lagos", code: "LOS", region: .africa),
        WorldCity(name: "Abuja", country: "Nigeria", countryCode: "NG", timezone: "Africa/Lagos", code: "ABV", region: .africa),
        WorldCity(name: "Accra", country: "Ghana", countryCode: "GH", timezone: "Africa/Accra", code: "ACC", region: .africa),
        WorldCity(name: "Dakar", country: "Senegal", countryCode: "SN", timezone: "Africa/Dakar", code: "DSS", region: .africa),
        WorldCity(name: "Abidjan", country: "Ivory Coast", countryCode: "CI", timezone: "Africa/Abidjan", code: "ABJ", region: .africa),

        // East Africa
        WorldCity(name: "Nairobi", country: "Kenya", countryCode: "KE", timezone: "Africa/Nairobi", code: "NBO", region: .africa),
        WorldCity(name: "Mombasa", country: "Kenya", countryCode: "KE", timezone: "Africa/Nairobi", code: "MBA", region: .africa),
        WorldCity(name: "Addis Ababa", country: "Ethiopia", countryCode: "ET", timezone: "Africa/Addis_Ababa", code: "ADD", region: .africa),
        WorldCity(name: "Dar es Salaam", country: "Tanzania", countryCode: "TZ", timezone: "Africa/Dar_es_Salaam", code: "DAR", region: .africa),
        WorldCity(name: "Zanzibar", country: "Tanzania", countryCode: "TZ", timezone: "Africa/Dar_es_Salaam", code: "ZNZ", region: .africa),
        WorldCity(name: "Kampala", country: "Uganda", countryCode: "UG", timezone: "Africa/Kampala", code: "EBB", region: .africa),
        WorldCity(name: "Kigali", country: "Rwanda", countryCode: "RW", timezone: "Africa/Kigali", code: "KGL", region: .africa),

        // Southern Africa
        WorldCity(name: "Johannesburg", country: "South Africa", countryCode: "ZA", timezone: "Africa/Johannesburg", code: "JNB", region: .africa),
        WorldCity(name: "Cape Town", country: "South Africa", countryCode: "ZA", timezone: "Africa/Johannesburg", code: "CPT", region: .africa),
        WorldCity(name: "Durban", country: "South Africa", countryCode: "ZA", timezone: "Africa/Johannesburg", code: "DUR", region: .africa),
        WorldCity(name: "Pretoria", country: "South Africa", countryCode: "ZA", timezone: "Africa/Johannesburg", code: "PRY", region: .africa),
        WorldCity(name: "Harare", country: "Zimbabwe", countryCode: "ZW", timezone: "Africa/Harare", code: "HRE", region: .africa),
        WorldCity(name: "Lusaka", country: "Zambia", countryCode: "ZM", timezone: "Africa/Lusaka", code: "LUN", region: .africa),
        WorldCity(name: "Maputo", country: "Mozambique", countryCode: "MZ", timezone: "Africa/Maputo", code: "MPM", region: .africa),
        WorldCity(name: "Windhoek", country: "Namibia", countryCode: "NA", timezone: "Africa/Windhoek", code: "WDH", region: .africa),
        WorldCity(name: "Gaborone", country: "Botswana", countryCode: "BW", timezone: "Africa/Gaborone", code: "GBE", region: .africa),
        WorldCity(name: "Port Louis", country: "Mauritius", countryCode: "MU", timezone: "Indian/Mauritius", code: "MRU", region: .africa),

        // ═══════════════════════════════════════════════════════════════
        // OCEANIA
        // ═══════════════════════════════════════════════════════════════

        // Australia
        WorldCity(name: "Sydney", country: "Australia", countryCode: "AU", timezone: "Australia/Sydney", code: "SYD", region: .oceania),
        WorldCity(name: "Melbourne", country: "Australia", countryCode: "AU", timezone: "Australia/Melbourne", code: "MEL", region: .oceania),
        WorldCity(name: "Brisbane", country: "Australia", countryCode: "AU", timezone: "Australia/Brisbane", code: "BNE", region: .oceania),
        WorldCity(name: "Perth", country: "Australia", countryCode: "AU", timezone: "Australia/Perth", code: "PER", region: .oceania),
        WorldCity(name: "Adelaide", country: "Australia", countryCode: "AU", timezone: "Australia/Adelaide", code: "ADL", region: .oceania),
        WorldCity(name: "Gold Coast", country: "Australia", countryCode: "AU", timezone: "Australia/Brisbane", code: "OOL", region: .oceania),
        WorldCity(name: "Cairns", country: "Australia", countryCode: "AU", timezone: "Australia/Brisbane", code: "CNS", region: .oceania),
        WorldCity(name: "Darwin", country: "Australia", countryCode: "AU", timezone: "Australia/Darwin", code: "DRW", region: .oceania),
        WorldCity(name: "Hobart", country: "Australia", countryCode: "AU", timezone: "Australia/Hobart", code: "HBA", region: .oceania),
        WorldCity(name: "Canberra", country: "Australia", countryCode: "AU", timezone: "Australia/Sydney", code: "CBR", region: .oceania),

        // New Zealand
        WorldCity(name: "Auckland", country: "New Zealand", countryCode: "NZ", timezone: "Pacific/Auckland", code: "AKL", region: .oceania),
        WorldCity(name: "Wellington", country: "New Zealand", countryCode: "NZ", timezone: "Pacific/Auckland", code: "WLG", region: .oceania),
        WorldCity(name: "Christchurch", country: "New Zealand", countryCode: "NZ", timezone: "Pacific/Auckland", code: "CHC", region: .oceania),
        WorldCity(name: "Queenstown", country: "New Zealand", countryCode: "NZ", timezone: "Pacific/Auckland", code: "ZQN", region: .oceania),

        // Pacific Islands
        WorldCity(name: "Suva", country: "Fiji", countryCode: "FJ", timezone: "Pacific/Fiji", code: "SUV", region: .oceania),
        WorldCity(name: "Port Moresby", country: "Papua New Guinea", countryCode: "PG", timezone: "Pacific/Port_Moresby", code: "POM", region: .oceania),
        WorldCity(name: "Nouméa", country: "New Caledonia", countryCode: "NC", timezone: "Pacific/Noumea", code: "NOU", region: .oceania),
        WorldCity(name: "Papeete", country: "French Polynesia", countryCode: "PF", timezone: "Pacific/Tahiti", code: "PPT", region: .oceania),
        WorldCity(name: "Apia", country: "Samoa", countryCode: "WS", timezone: "Pacific/Apia", code: "APW", region: .oceania),
        WorldCity(name: "Nadi", country: "Fiji", countryCode: "FJ", timezone: "Pacific/Fiji", code: "NAN", region: .oceania),
        WorldCity(name: "Guam", country: "Guam", countryCode: "GU", timezone: "Pacific/Guam", code: "GUM", region: .oceania),
    ]

    // MARK: - Search Functions

    /// Search cities by name, country, or code (情報デザイン: intelligent matching)
    /// - Parameter query: Search string
    /// - Returns: Matching cities, sorted by relevance
    static func search(_ query: String) -> [WorldCity] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return [] }

        // Score and filter cities
        var scored: [(city: WorldCity, score: Int)] = []

        for city in cities {
            var score = 0
            let cityLower = city.name.lowercased()
            let countryLower = city.country.lowercased()
            let codeLower = city.code.lowercased()

            // Exact city name match (highest priority)
            if cityLower == trimmedQuery {
                score = 100
            }
            // City name starts with query
            else if cityLower.hasPrefix(trimmedQuery) {
                score = 80
            }
            // Exact code match
            else if codeLower == trimmedQuery {
                score = 75
            }
            // Exact country match
            else if countryLower == trimmedQuery {
                score = 70
            }
            // Country starts with query
            else if countryLower.hasPrefix(trimmedQuery) {
                score = 60
            }
            // City name contains query
            else if cityLower.contains(trimmedQuery) {
                score = 50
            }
            // Country contains query
            else if countryLower.contains(trimmedQuery) {
                score = 40
            }
            // Any keyword contains query
            else if city.searchKeywords.contains(trimmedQuery) {
                score = 30
            }

            if score > 0 {
                scored.append((city, score))
            }
        }

        // Sort by score descending, then alphabetically
        return scored
            .sorted { $0.score > $1.score || ($0.score == $1.score && $0.city.name < $1.city.name) }
            .prefix(20)
            .map { $0.city }
    }

    /// Get timezone for a city or country name
    static func timezone(for query: String) -> TimeZone? {
        guard let city = search(query).first else { return nil }
        return TimeZone(identifier: city.timezone)
    }

    /// Get default city (STM - Stora Mellösa)
    static var defaultCity: WorldCity {
        cities.first { $0.code == "STM" } ?? cities[0]
    }

    /// Get cities by region
    static func cities(in region: WorldRegion) -> [WorldCity] {
        cities.filter { $0.region == region }
    }
}
