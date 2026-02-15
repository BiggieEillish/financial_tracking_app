import 'dart:math';
import '../repositories/expense_group_repository.dart';

class MockDataService {
  final ExpenseGroupRepository _repository;
  final String _userId;
  final _random = Random(42); // Fixed seed for reproducibility

  MockDataService(this._repository, this._userId);

  /// Generate a comprehensive set of mock expenses that train the classifier well.
  /// Returns the number of expense groups created.
  Future<int> generateMockData() async {
    final now = DateTime.now();
    int groupCount = 0;

    for (final entry in _mockExpenses.entries) {
      final category = entry.key;
      final items = entry.value;

      for (final item in items) {
        final daysAgo = _random.nextInt(90); // Spread across 3 months
        final date = now.subtract(Duration(days: daysAgo));

        await _repository.addExpenseGroup(
          userId: _userId,
          date: date,
          items: [
            ExpenseGroupItemData(
              amount: item.amount,
              category: category,
              description: item.description,
            ),
          ],
        );
        groupCount++;
      }
    }

    // Add multi-item receipt groups (store receipts)
    for (final receipt in _mockReceipts) {
      final daysAgo = _random.nextInt(60);
      final date = now.subtract(Duration(days: daysAgo));

      await _repository.addExpenseGroup(
        userId: _userId,
        date: date,
        storeName: receipt.storeName,
        items: receipt.items
            .map((i) => ExpenseGroupItemData(
                  amount: i.amount,
                  category: i.category,
                  description: i.description,
                  quantity: i.quantity,
                ))
            .toList(),
      );
      groupCount++;
    }

    return groupCount;
  }
}

class _MockItem {
  final String description;
  final double amount;
  const _MockItem(this.description, this.amount);
}

class _MockReceiptItem {
  final String description;
  final double amount;
  final String category;
  final int quantity;
  const _MockReceiptItem(this.description, this.amount, this.category,
      [this.quantity = 1]);
}

class _MockReceipt {
  final String storeName;
  final List<_MockReceiptItem> items;
  const _MockReceipt(this.storeName, this.items);
}

// ─── Single-item expenses per category ─────────────────────────
const _mockExpenses = <String, List<_MockItem>>{
  'Food & Dining': [
    _MockItem('Nasi lemak ayam rendang at mamak', 8.50),
    _MockItem('McDonald lunch set Big Mac meal', 15.90),
    _MockItem('Starbucks caramel macchiato grande', 18.50),
    _MockItem('KFC dinner bucket meal family', 45.90),
    _MockItem('Grab Food delivery roti canai and teh tarik', 12.80),
    _MockItem('Pizza Hut regular pepperoni cheese', 29.90),
    _MockItem('Nasi goreng kampung food court', 7.50),
    _MockItem('Subway footlong chicken teriyaki', 19.90),
    _MockItem('Sushi King set lunch bento', 22.00),
    _MockItem('Tealive brown sugar milk tea boba', 9.90),
    _MockItem('Old Town White Coffee breakfast set', 13.50),
    _MockItem('Nasi kandar with curry chicken', 10.00),
    _MockItem('Foodpanda delivery Thai basil chicken rice', 16.50),
    _MockItem('Secret Recipe cake slice chocolate indulgence', 12.90),
    _MockItem('Bakery bread loaf gardenia wholemeal', 4.50),
    _MockItem('Mee goreng mamak with telur special', 9.00),
    _MockItem('Coffee bean latte iced blended', 16.90),
    _MockItem('Dim sum breakfast at restaurant', 35.00),
    _MockItem('Mixed rice economy with vegetables and fish', 8.00),
    _MockItem('Roti bakar set with half boiled egg', 5.50),
  ],
  'Transportation': [
    _MockItem('Grab ride from home to office KL', 15.00),
    _MockItem('Petrol Shell V-Power full tank', 120.00),
    _MockItem('Touch n Go reload highway toll', 50.00),
    _MockItem('Parking KLCC basement hourly', 8.00),
    _MockItem('LRT rapid transit monthly pass topup', 100.00),
    _MockItem('Petronas fuel pump RON95', 80.00),
    _MockItem('Toll LPT highway Seremban KL', 12.60),
    _MockItem('Bus ticket KL Sentral to Putrajaya', 5.00),
    _MockItem('Grab car airport KLIA transfer', 75.00),
    _MockItem('MRT feeder bus rapid transit', 3.00),
    _MockItem('Parking meter street side hourly', 4.00),
    _MockItem('EWallet TnG reload for toll payment', 100.00),
    _MockItem('KTM Komuter train ticket to Subang', 6.50),
  ],
  'Shopping': [
    _MockItem('Lazada online purchase wireless earbuds', 89.00),
    _MockItem('Shopee sale clothes cotton t-shirt', 35.00),
    _MockItem('Uniqlo jeans slim fit denim', 149.00),
    _MockItem('Mr DIY household supplies and tools', 45.60),
    _MockItem('Daiso kitchen accessories storage', 21.20),
    _MockItem('AEON mall shoes Nike running', 299.00),
    _MockItem('Watsons skincare and toiletries', 67.80),
    _MockItem('Guardian pharmacy shampoo conditioner', 32.50),
    _MockItem('Cotton On kids clothing sale', 55.00),
    _MockItem('Ikea home decor cushion covers', 79.90),
    _MockItem('Padini jacket winter outerwear', 99.00),
    _MockItem('Shopee electronics phone case charger', 25.00),
  ],
  'Entertainment': [
    _MockItem('GSC cinema movie ticket two persons', 36.00),
    _MockItem('Netflix monthly subscription premium', 54.90),
    _MockItem('Spotify premium music streaming', 14.90),
    _MockItem('TGV IMAX movie ticket popcorn combo', 55.00),
    _MockItem('PlayStation Plus annual subscription gaming', 189.00),
    _MockItem('Karaoke session RedBox weekend', 45.00),
    _MockItem('Disney Plus Hotstar subscription monthly', 34.90),
    _MockItem('Board game cafe tabletop session', 30.00),
    _MockItem('Concert ticket live show Axiata Arena', 250.00),
    _MockItem('Steam game purchase indie title', 35.00),
    _MockItem('YouTube Premium subscription ad-free', 22.90),
    _MockItem('Bowling Sunway Pyramid weekend game', 28.00),
  ],
  'Bills & Utilities': [
    _MockItem('TNB electricity bill monthly home', 180.00),
    _MockItem('Unifi internet broadband monthly', 149.00),
    _MockItem('Water bill Syabas monthly payment', 25.00),
    _MockItem('Maxis mobile postpaid phone bill', 98.00),
    _MockItem('Celcom prepaid topup reload mobile', 30.00),
    _MockItem('Astro TV satellite subscription', 99.90),
    _MockItem('Digi broadband internet plan monthly', 40.00),
    _MockItem('Indah Water sewerage bill quarterly', 8.00),
    _MockItem('TM Unifi fiber internet upgrade', 199.00),
    _MockItem('Gas bill monthly cooking LPG cylinder', 28.00),
  ],
  'Auto & Transport': [
    _MockItem('Car service workshop engine oil change', 250.00),
    _MockItem('Tyre replacement Michelin front pair', 600.00),
    _MockItem('Car wash and interior detailing', 35.00),
    _MockItem('Battery replacement Amaron car', 350.00),
    _MockItem('Road tax renewal annual vehicle', 90.00),
    _MockItem('Car insurance Allianz comprehensive renewal', 1800.00),
    _MockItem('Windshield wiper replacement auto parts', 45.00),
    _MockItem('Alignment and balancing wheel service', 80.00),
    _MockItem('Motorcycle service chain oil spark plug', 120.00),
    _MockItem('Air conditioning regas car workshop', 150.00),
  ],
  'Travel': [
    _MockItem('AirAsia flight ticket KL to Langkawi', 189.00),
    _MockItem('Hotel booking Agoda Penang resort', 320.00),
    _MockItem('Holiday trip Cameron Highlands accommodation', 250.00),
    _MockItem('Malaysia Airlines flight Sabah Kota Kinabalu', 450.00),
    _MockItem('Airbnb weekend getaway Port Dickson', 180.00),
    _MockItem('Airport KLIA lounge access pass', 120.00),
    _MockItem('Travel insurance AIG international trip', 85.00),
    _MockItem('Luggage bag Samsonite cabin size', 399.00),
    _MockItem('Tour package Genting day trip', 150.00),
    _MockItem('Booking.com hotel Melaka heritage city', 280.00),
  ],
  'Fees & Charges': [
    _MockItem('Bank transfer fee CIMB to Maybank', 1.00),
    _MockItem('ATM withdrawal service charge interbank', 1.00),
    _MockItem('Credit card annual fee waiver request', 0.00),
    _MockItem('Late payment penalty credit card', 25.00),
    _MockItem('Processing fee loan application', 50.00),
    _MockItem('Government stamp duty agreement', 10.00),
    _MockItem('DuitNow transfer fund charge', 0.50),
    _MockItem('Foreign exchange conversion fee', 15.00),
    _MockItem('Cheque book issuance bank fee', 12.00),
  ],
  'Business Services': [
    _MockItem('Printing photostat documents office', 15.00),
    _MockItem('Adobe Creative Cloud subscription monthly', 52.00),
    _MockItem('Domain name renewal GoDaddy annual', 55.00),
    _MockItem('Google Workspace business email', 25.00),
    _MockItem('Cloud server hosting DigitalOcean monthly', 30.00),
    _MockItem('Canva Pro design subscription annual', 50.00),
    _MockItem('Office stationery supply pen paper folder', 22.00),
    _MockItem('Business card printing urgent order', 40.00),
    _MockItem('Marketing Facebook ads boost promotion', 100.00),
    _MockItem('Zoom Pro meeting subscription monthly', 55.00),
  ],
  'Education': [
    _MockItem('Tuition fee semester university UKM', 3500.00),
    _MockItem('Udemy online course web development', 49.90),
    _MockItem('Textbook purchase academic reference', 85.00),
    _MockItem('Exam registration IELTS test', 850.00),
    _MockItem('Coursera Plus annual subscription learning', 250.00),
    _MockItem('Children tuition class mathematics weekly', 200.00),
    _MockItem('School supply stationery notebook pen', 35.00),
    _MockItem('Workshop training digital marketing', 300.00),
    _MockItem('Piano lesson music class monthly', 180.00),
    _MockItem('Kindergarten monthly fee childcare', 800.00),
  ],
  'Health & Medical': [
    _MockItem('Doctor consultation clinic visit GP', 65.00),
    _MockItem('Pharmacy prescription medicine paracetamol', 15.00),
    _MockItem('Dental cleaning checkup scaling', 120.00),
    _MockItem('Specialist appointment dermatologist', 150.00),
    _MockItem('Supplement vitamin C zinc health', 45.00),
    _MockItem('Blood test medical lab screening', 250.00),
    _MockItem('Physiotherapy session back pain treatment', 90.00),
    _MockItem('Eye checkup optometrist glasses prescription', 80.00),
    _MockItem('Hospital emergency room visit treatment', 350.00),
    _MockItem('Traditional Chinese medicine herbs TCM', 60.00),
  ],
  'Home': [
    _MockItem('Monthly rent apartment condominium payment', 1500.00),
    _MockItem('Furniture IKEA bookshelf assembly', 299.00),
    _MockItem('Plumber repair leaking pipe kitchen', 150.00),
    _MockItem('Cleaning supply Dettol detergent bleach', 35.00),
    _MockItem('Aircond maintenance service washing filter', 80.00),
    _MockItem('Curtain new bedroom window blind', 120.00),
    _MockItem('Electrical repair wiring socket switch', 200.00),
    _MockItem('Pest control termite treatment annual', 280.00),
    _MockItem('Water filter cartridge replacement', 55.00),
    _MockItem('Light bulb LED replacement Philips', 22.00),
  ],
  'Personal Care': [
    _MockItem('Haircut barber shop men grooming', 25.00),
    _MockItem('Hair salon treatment colouring ladies', 180.00),
    _MockItem('Skincare Innisfree cleanser moisturizer', 75.00),
    _MockItem('Gym membership fitness first monthly', 150.00),
    _MockItem('Spa massage body relaxation treatment', 120.00),
    _MockItem('Facial treatment beauty salon session', 90.00),
    _MockItem('Perfume Calvin Klein fragrance purchase', 250.00),
    _MockItem('Makeup Maybelline foundation concealer', 55.00),
    _MockItem('Nail salon manicure pedicure session', 60.00),
    _MockItem('Contact lens monthly disposable pair', 70.00),
  ],
  'Gifts & Donations': [
    _MockItem('Birthday gift present for friend', 80.00),
    _MockItem('Zakat fitrah payment Ramadan annual', 14.00),
    _MockItem('Wedding angpau cash gift reception', 200.00),
    _MockItem('Charity donation orphanage contribution', 100.00),
    _MockItem('Duit raya Hari Raya Aidilfitri packets', 150.00),
    _MockItem('Flower bouquet anniversary celebration', 85.00),
    _MockItem('Christmas gift exchange present', 60.00),
    _MockItem('Baby shower gift newborn clothes', 70.00),
    _MockItem('Teacher appreciation day gift voucher', 50.00),
    _MockItem('Mosque surau donation Friday prayer', 20.00),
  ],
  'Investments': [
    _MockItem('Stock purchase CIMB shares Bursa Malaysia', 500.00),
    _MockItem('ASB Amanah Saham Bumiputera deposit', 1000.00),
    _MockItem('EPF voluntary contribution extra savings', 500.00),
    _MockItem('Unit trust Public Mutual fund investment', 300.00),
    _MockItem('Gold savings account Maybank purchase', 200.00),
    _MockItem('Crypto Bitcoin purchase Luno exchange', 150.00),
    _MockItem('REIT dividend reinvestment property trust', 400.00),
    _MockItem('Fixed deposit placement bank term', 5000.00),
    _MockItem('Stashaway robo advisor portfolio top up', 250.00),
    _MockItem('Wahed Invest halal fund contribution', 200.00),
  ],
  'Other': [
    _MockItem('Miscellaneous expense petty cash', 10.00),
    _MockItem('Cash withdrawal ATM sundry spending', 200.00),
    _MockItem('Lost item replacement umbrella', 15.00),
    _MockItem('Courier delivery Poslaju parcel', 8.00),
    _MockItem('Laundry service dry cleaning suit', 25.00),
  ],
};

// ─── Multi-item receipt groups ─────────────────────────────────
const _mockReceipts = <_MockReceipt>[
  _MockReceipt('AEON Big Supermarket', [
    _MockReceiptItem('Fresh chicken breast kg', 12.50, 'Food & Dining'),
    _MockReceiptItem('Jasmine rice 5kg bag', 28.00, 'Food & Dining'),
    _MockReceiptItem('Cooking oil palm olein', 8.90, 'Food & Dining'),
    _MockReceiptItem('Dettol hand soap refill', 9.50, 'Home'),
    _MockReceiptItem('Tissue paper 3-ply pack', 12.90, 'Home'),
    _MockReceiptItem('Fresh milk farm 1L', 7.50, 'Food & Dining'),
  ]),
  _MockReceipt('Jaya Grocer', [
    _MockReceiptItem('Salmon fillet imported', 35.00, 'Food & Dining'),
    _MockReceiptItem('Avocado fresh organic', 8.90, 'Food & Dining', 2),
    _MockReceiptItem('Greek yogurt plain', 12.50, 'Food & Dining'),
    _MockReceiptItem('Granola cereal oats', 18.00, 'Food & Dining'),
    _MockReceiptItem('Sparkling water San Pellegrino', 6.50, 'Food & Dining', 3),
  ]),
  _MockReceipt('Watsons Pharmacy', [
    _MockReceiptItem('Paracetamol tablets pain relief', 8.50, 'Health & Medical'),
    _MockReceiptItem('Vitamin D3 supplement daily', 35.00, 'Health & Medical'),
    _MockReceiptItem('Face wash cleanser Cetaphil', 42.00, 'Personal Care'),
    _MockReceiptItem('Sunscreen SPF50 body lotion', 38.00, 'Personal Care'),
    _MockReceiptItem('Toothpaste Colgate whitening', 12.90, 'Personal Care'),
  ]),
  _MockReceipt('Mr DIY Hardware', [
    _MockReceiptItem('LED light bulb 12W', 8.90, 'Home', 3),
    _MockReceiptItem('Extension cord 3 meter', 15.00, 'Home'),
    _MockReceiptItem('Wall hook adhesive pack', 5.90, 'Home'),
    _MockReceiptItem('Cable tie organizer set', 4.50, 'Home'),
    _MockReceiptItem('Battery AAA alkaline', 9.90, 'Home', 2),
  ]),
  _MockReceipt('99 Speedmart', [
    _MockReceiptItem('Milo chocolate drink packet', 15.90, 'Food & Dining'),
    _MockReceiptItem('Maggi instant noodle curry', 5.50, 'Food & Dining', 5),
    _MockReceiptItem('Dutch Lady milk UHT', 6.90, 'Food & Dining', 2),
    _MockReceiptItem('Gardenia bread white', 3.80, 'Food & Dining'),
    _MockReceiptItem('Sugar fine granulated 1kg', 3.50, 'Food & Dining'),
  ]),
  _MockReceipt('Popular Bookstore', [
    _MockReceiptItem('Notebook A4 hardcover journal', 18.90, 'Education'),
    _MockReceiptItem('Ballpoint pen Pilot pack', 12.50, 'Education'),
    _MockReceiptItem('Novel fiction bestseller book', 39.90, 'Entertainment'),
    _MockReceiptItem('Highlighter neon marker set', 8.50, 'Education'),
  ]),
  _MockReceipt('Petronas Mesra', [
    _MockReceiptItem('RON95 petrol fuel pump', 95.00, 'Transportation'),
    _MockReceiptItem('Mineral water bottle 1.5L', 2.50, 'Food & Dining'),
    _MockReceiptItem('Curry puff snack pastry', 3.00, 'Food & Dining', 2),
  ]),
];
