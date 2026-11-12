import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Semantic groups used to filter icons inside [IconAndColorPicker].
enum AppIconGroup {
  all,
  finance,
  food,
  transport,
  home,
  shopping,
  life,
  leisure,
}

/// Tree-shake-safe catalog of Material Symbols and Cupertino Icons for wallets,
/// categories, savings goals, and ledgers.
///
/// Using constant icon references guarantees Android & iOS release builds pass
/// `--tree-shake-icons` without runtime missing-glyph issues.
abstract final class AppIconCatalog {
  static const Map<String, IconData> icons = {
    // Wallets & Finance
    'wallet': Icons.account_balance_wallet_rounded,
    'cash': Icons.payments_rounded,
    'bank': Icons.account_balance_rounded,
    'ewallet': Icons.qr_code_2_rounded,
    'card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,
    'vault': Icons.lock_rounded,
    'gold': Icons.diamond_rounded,
    'stocks': Icons.candlestick_chart_rounded,
    'salary': Icons.work_rounded,
    'bonus': Icons.workspace_premium_rounded,
    'investment': Icons.trending_up_rounded,
    'dividend': Icons.percent_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'business': Icons.storefront_rounded,
    'loan': Icons.handshake_rounded,
    'refund': Icons.currency_exchange_rounded,
    'allowance': Icons.card_giftcard_rounded,
    'transfer': Icons.swap_horiz_rounded,

    // Food & Drinks
    'food': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'bakery': Icons.bakery_dining_rounded,
    'bar': Icons.local_bar_rounded,
    'delivery': Icons.delivery_dining_rounded,
    'cooking': Icons.soup_kitchen_rounded,

    // Transport & Vehicles
    'transport': Icons.directions_car_rounded,
    'motorbike': Icons.two_wheeler_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'bus': Icons.directions_bus_rounded,
    'taxi': Icons.local_taxi_rounded,
    'parking': Icons.local_parking_rounded,
    'car_repair': Icons.car_repair_rounded,
    'train': Icons.train_rounded,

    // Housing & Bills
    'housing': Icons.home_rounded,
    'bills': Icons.receipt_long_rounded,
    'electricity': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'wifi': Icons.wifi_rounded,
    'phone': Icons.smartphone_rounded,
    'furniture': Icons.chair_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'tools': Icons.build_rounded,

    // Shopping & Lifestyle
    'shopping': Icons.shopping_bag_rounded,
    'clothes': Icons.checkroom_rounded,
    'beauty': Icons.spa_rounded,
    'haircut': Icons.content_cut_rounded,
    'electronics': Icons.devices_rounded,
    'watch': Icons.watch_rounded,
    'subscription': Icons.subscriptions_rounded,

    // Health, Education & Family
    'health': Icons.medical_services_rounded,
    'medicine': Icons.medication_rounded,
    'fitness': Icons.fitness_center_rounded,
    'sports': Icons.sports_soccer_rounded,
    'education': Icons.school_rounded,
    'books': Icons.menu_book_rounded,
    'family': Icons.family_restroom_rounded,
    'baby': Icons.child_care_rounded,
    'wedding': Icons.favorite_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'pets': Icons.pets_rounded,
    'gift': Icons.redeem_rounded,

    // Entertainment, Travel & Other
    'entertainment': Icons.movie_rounded,
    'gaming': Icons.sports_esports_rounded,
    'music': Icons.music_note_rounded,
    'camera': Icons.photo_camera_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'hotel': Icons.hotel_rounded,
    'beach': Icons.beach_access_rounded,
    'other': Icons.category_rounded,
  };

  /// Keys grouped by domain for quick filtering in icon pickers.
  static const Map<AppIconGroup, List<String>> groupedKeys = {
    AppIconGroup.finance: [
      'wallet',
      'cash',
      'bank',
      'ewallet',
      'card',
      'savings',
      'vault',
      'gold',
      'stocks',
      'salary',
      'bonus',
      'investment',
      'dividend',
      'freelance',
      'business',
      'loan',
      'refund',
      'allowance',
      'transfer',
    ],
    AppIconGroup.food: [
      'food',
      'coffee',
      'fastfood',
      'groceries',
      'bakery',
      'bar',
      'delivery',
      'cooking',
    ],
    AppIconGroup.transport: [
      'transport',
      'motorbike',
      'fuel',
      'bus',
      'taxi',
      'parking',
      'car_repair',
      'train',
    ],
    AppIconGroup.home: [
      'housing',
      'bills',
      'electricity',
      'water',
      'wifi',
      'phone',
      'furniture',
      'cleaning',
      'tools',
    ],
    AppIconGroup.shopping: [
      'shopping',
      'clothes',
      'beauty',
      'haircut',
      'electronics',
      'watch',
      'subscription',
    ],
    AppIconGroup.life: [
      'health',
      'medicine',
      'fitness',
      'sports',
      'education',
      'books',
      'family',
      'baby',
      'wedding',
      'charity',
      'pets',
      'gift',
    ],
    AppIconGroup.leisure: [
      'entertainment',
      'gaming',
      'music',
      'camera',
      'travel',
      'hotel',
      'beach',
      'other',
    ],
  };

  /// Curated list of wallet icon keys with short Vietnamese display labels.
  static const List<(String key, String viLabel)> walletIconItems = [
    ('cash', 'Tiền mặt'),
    ('bank', 'Ngân hàng'),
    ('ewallet', 'Ví điện tử'),
    ('card', 'Thẻ'),
    ('savings', 'Tiết kiệm'),
    ('wallet', 'Ví chính'),
    ('vault', 'Két sắt'),
    ('gold', 'Vàng'),
    ('stocks', 'Chứng khoán'),
    ('salary', 'Lương'),
    ('investment', 'Đầu tư'),
    ('business', 'Kinh doanh'),
    ('family', 'Gia đình'),
    ('travel', 'Du lịch'),
    ('housing', 'Nhà ở'),
    ('transport', 'Xe cộ'),
    ('allowance', 'Phụ cấp'),
    ('refund', 'Hoàn tiền'),
    ('gift', 'Quà / Thưởng'),
    ('other', 'Khác'),
  ];

  static List<String> get walletKeys =>
      walletIconItems.map((e) => e.$1).toList(growable: false);

  /// Curated icon options for Savings Goals (key, icon, label).
  static const List<(String key, IconData icon, String label)> savingsIcons = [
    ('piggy_bank', CupertinoIcons.cube_box, 'Heo đất'),
    ('shield', CupertinoIcons.shield_fill, 'Khẩn cấp'),
    ('house', CupertinoIcons.house_fill, 'Nhà cửa'),
    ('car', CupertinoIcons.car_detailed, 'Ô tô'),
    ('bike', Icons.two_wheeler_rounded, 'Xe máy'),
    ('airplane', CupertinoIcons.airplane, 'Du lịch'),
    ('beach', CupertinoIcons.sun_max_fill, 'Nghỉ dưỡng'),
    ('laptop', CupertinoIcons.device_laptop, 'Thiết bị'),
    ('camera', CupertinoIcons.camera_fill, 'Máy ảnh'),
    ('gaming', CupertinoIcons.gamecontroller_fill, 'Giải trí / Game'),
    ('gift', CupertinoIcons.gift_fill, 'Quà tặng'),
    ('wedding', CupertinoIcons.heart_circle_fill, 'Cưới hỏi'),
    ('baby', Icons.child_care_rounded, 'Con cái'),
    ('heart', CupertinoIcons.heart_fill, 'Sức khỏe'),
    ('education', Icons.school_rounded, 'Học vấn'),
    ('book', CupertinoIcons.book_fill, 'Sách / Khóa học'),
    ('gold', Icons.diamond_rounded, 'Vàng / Trang sức'),
    ('business', CupertinoIcons.briefcase_fill, 'Khởi nghiệp'),
    ('pet', Icons.pets_rounded, 'Thú cưng'),
    ('bag', CupertinoIcons.bag_fill, 'Mua sắm'),
    ('music', CupertinoIcons.music_note_2, 'Âm nhạc'),
    ('star', CupertinoIcons.star_fill, 'Mục tiêu'),
    ('rocket', CupertinoIcons.rocket_fill, 'Ước mơ'),
    ('savings', Icons.savings_rounded, 'Tích lũy'),
  ];

  /// Resolves a savings goal icon key to its icon for form previews and detail headers.
  static IconData resolveSavingsIcon(String key, {bool useOutlineCard = false}) {
    if (useOutlineCard) {
      return switch (key) {
        'house' => CupertinoIcons.house,
        'car' => CupertinoIcons.car,
        'bag' => CupertinoIcons.bag,
        'gift' => CupertinoIcons.gift,
        'piggy_bank' => Icons.savings_rounded,
        _ => resolveSavingsIcon(key),
      };
    }
    for (final item in savingsIcons) {
      if (item.$1 == key) return item.$2;
    }
    return Icons.savings_rounded;
  }

  /// Curated icon options for Multi-Ledger / Bookkeeping Ledgers.
  static const List<(String key, IconData icon, String label)> ledgerIcons = [
    ('person', CupertinoIcons.person_crop_circle_fill, 'Cá nhân'),
    ('family', CupertinoIcons.person_3_fill, 'Gia đình'),
    ('couple', CupertinoIcons.heart_circle_fill, 'Cặp đôi'),
    ('briefcase', CupertinoIcons.briefcase_fill, 'Công việc'),
    ('store', Icons.storefront_rounded, 'Cửa hàng'),
    ('wallet', CupertinoIcons.creditcard_fill, 'Quỹ riêng'),
    ('savings', Icons.savings_rounded, 'Tích lũy'),
    ('star', CupertinoIcons.star_fill, 'Đặc biệt'),
    ('airplane', CupertinoIcons.airplane, 'Du lịch'),
    ('cart', CupertinoIcons.cart_fill, 'Mua sắm'),
    ('home', CupertinoIcons.house_fill, 'Nhà cửa'),
    ('car', CupertinoIcons.car_detailed, 'Xe cộ'),
    ('school', CupertinoIcons.book_fill, 'Học tập'),
    ('chart', CupertinoIcons.chart_bar_alt_fill, 'Đầu tư'),
    ('heart', CupertinoIcons.heart_fill, 'Sức khỏe'),
    ('food', Icons.restaurant_rounded, 'Ăn uống'),
    ('fitness', Icons.fitness_center_rounded, 'Thể thao'),
    ('gift', CupertinoIcons.gift_fill, 'Quà tặng'),
    ('pets', Icons.pets_rounded, 'Thú cưng'),
    ('camera', CupertinoIcons.camera_fill, 'Sở thích'),
    ('game', CupertinoIcons.gamecontroller_fill, 'Giải trí'),
    ('shield', CupertinoIcons.shield_fill, 'Dự phòng'),
    ('club', CupertinoIcons.flag_fill, 'Nhóm / CLB'),
    ('other', CupertinoIcons.square_grid_2x2_fill, 'Khác'),
  ];

  /// Resolves a ledger icon key to its icon across pills, switcher sheets, and cards.
  static IconData resolveLedgerIcon(String key) {
    for (final item in ledgerIcons) {
      if (item.$1 == key) return item.$2;
    }
    return CupertinoIcons.person_crop_circle_fill;
  }

  static List<String> get keys => icons.keys.toList(growable: false);

  static List<String> keysForGroup(AppIconGroup group) {
    if (group == AppIconGroup.all) return keys;
    return groupedKeys[group] ?? const [];
  }

  static String groupLabel(AppIconGroup group, {required bool isVi}) {
    return switch (group) {
      AppIconGroup.all => isVi ? 'Tất cả' : 'All',
      AppIconGroup.finance => isVi ? 'Ví & Tiền' : 'Finance',
      AppIconGroup.food => isVi ? 'Ăn uống' : 'Food',
      AppIconGroup.transport => isVi ? 'Di chuyển' : 'Transport',
      AppIconGroup.home => isVi ? 'Nhà & Hóa đơn' : 'Home & Bills',
      AppIconGroup.shopping => isVi ? 'Mua sắm' : 'Shopping',
      AppIconGroup.life => isVi ? 'Sức khỏe & GĐ' : 'Life & Study',
      AppIconGroup.leisure => isVi ? 'Giải trí' : 'Leisure',
    };
  }

  static IconData resolve(String key) => icons[key] ?? Icons.category_rounded;

  /// Ensures >= 3:1 non-text contrast for icons rendered against dark surfaces.
  static Color contrastSafeColor(Color base, Brightness brightness) {
    if (brightness == Brightness.light) return base;
    final hsl = HSLColor.fromColor(base);
    if (hsl.lightness < 0.62) {
      return hsl.withLightness(0.66).toColor();
    }
    return base;
  }

  /// Localized human-readable label for screen readers (TalkBack / VoiceOver).
  static String iconAccessibilityLabel(String key, {required bool isVi}) {
    return switch (key) {
      'wallet' => isVi ? 'Ví tiền' : 'Wallet',
      'cash' => isVi ? 'Tiền mặt' : 'Cash',
      'bank' => isVi ? 'Ngân hàng' : 'Bank',
      'ewallet' => isVi ? 'Ví điện tử' : 'E-wallet',
      'card' => isVi ? 'Thẻ' : 'Card',
      'savings' => isVi ? 'Tiết kiệm' : 'Savings',
      'vault' => isVi ? 'Két sắt' : 'Vault',
      'gold' => isVi ? 'Vàng & Đá quý' : 'Gold',
      'stocks' => isVi ? 'Chứng khoán' : 'Stocks',
      'salary' => isVi ? 'Lương' : 'Salary',
      'bonus' => isVi ? 'Thưởng' : 'Bonus',
      'investment' => isVi ? 'Đầu tư' : 'Investment',
      'dividend' => isVi ? 'Cổ tức & Lãi suất' : 'Dividend',
      'freelance' => isVi ? 'Việc làm thêm' : 'Freelance',
      'business' => isVi ? 'Kinh doanh' : 'Business',
      'loan' => isVi ? 'Vay & Trả nợ' : 'Loan',
      'refund' => isVi ? 'Hoàn tiền' : 'Refund',
      'allowance' => isVi ? 'Phụ cấp' : 'Allowance',
      'transfer' => isVi ? 'Chuyển khoản' : 'Transfer',
      'food' => isVi ? 'Ăn uống' : 'Food',
      'coffee' => isVi ? 'Cà phê' : 'Coffee',
      'fastfood' => isVi ? 'Đồ ăn nhanh' : 'Fast food',
      'groceries' => isVi ? 'Siêu thị & Đi chợ' : 'Groceries',
      'bakery' => isVi ? 'Bánh ngọt & Ăn sáng' : 'Bakery',
      'bar' => isVi ? 'Tiệc & Đồ uống' : 'Drinks & Party',
      'delivery' => isVi ? 'Giao đồ ăn' : 'Food delivery',
      'cooking' => isVi ? 'Nấu ăn' : 'Cooking',
      'transport' => isVi ? 'Di chuyển / Ô tô' : 'Car & Transport',
      'motorbike' => isVi ? 'Xe máy' : 'Motorbike',
      'fuel' => isVi ? 'Xăng dầu' : 'Fuel',
      'bus' => isVi ? 'Xe buýt' : 'Bus',
      'taxi' => isVi ? 'Taxi & Xe công nghệ' : 'Taxi',
      'parking' => isVi ? 'Gửi xe' : 'Parking',
      'car_repair' => isVi ? 'Bảo dưỡng xe' : 'Car maintenance',
      'train' => isVi ? 'Tàu hỏa' : 'Train',
      'housing' => isVi ? 'Nhà ở' : 'Housing',
      'bills' => isVi ? 'Hóa đơn' : 'Bills',
      'electricity' => isVi ? 'Tiền điện' : 'Electricity',
      'water' => isVi ? 'Tiền nước' : 'Water',
      'wifi' => isVi ? 'Internet & Wifi' : 'Internet & Wifi',
      'phone' => isVi ? 'Điện thoại' : 'Phone',
      'furniture' => isVi ? 'Nội thất' : 'Furniture',
      'cleaning' => isVi ? 'Dọn dẹp & Giặt ủi' : 'Cleaning',
      'tools' => isVi ? 'Sửa chữa' : 'Repairs',
      'shopping' => isVi ? 'Mua sắm' : 'Shopping',
      'clothes' => isVi ? 'Quần áo' : 'Clothing',
      'beauty' => isVi ? 'Làm đẹp & Spa' : 'Beauty & Spa',
      'haircut' => isVi ? 'Cắt tóc' : 'Haircut',
      'electronics' => isVi ? 'Đồ công nghệ' : 'Electronics',
      'watch' => isVi ? 'Phụ kiện & Đồng hồ' : 'Accessories',
      'subscription' => isVi ? 'Gói đăng ký' : 'Subscriptions',
      'health' => isVi ? 'Sức khỏe' : 'Health',
      'medicine' => isVi ? 'Thuốc men' : 'Medicine',
      'fitness' => isVi ? 'Gym & Thể hình' : 'Fitness',
      'sports' => isVi ? 'Thể thao' : 'Sports',
      'education' => isVi ? 'Giáo dục' : 'Education',
      'books' => isVi ? 'Sách vở' : 'Books',
      'family' => isVi ? 'Gia đình' : 'Family',
      'baby' => isVi ? 'Con cái' : 'Baby & Kids',
      'wedding' => isVi ? 'Hiếu hỉ & Cưới hỏi' : 'Wedding',
      'charity' => isVi ? 'Từ thiện' : 'Charity',
      'pets' => isVi ? 'Thú cưng' : 'Pets',
      'gift' => isVi ? 'Quà tặng' : 'Gift',
      'entertainment' => isVi ? 'Giải trí' : 'Entertainment',
      'gaming' => isVi ? 'Trò chơi' : 'Gaming',
      'music' => isVi ? 'Âm nhạc' : 'Music',
      'camera' => isVi ? 'Nhiếp ảnh' : 'Photography',
      'travel' => isVi ? 'Du lịch' : 'Travel',
      'hotel' => isVi ? 'Khách sạn' : 'Hotel',
      'beach' => isVi ? 'Nghỉ dưỡng' : 'Beach & Resort',
      _ => isVi ? 'Khác' : 'Other',
    };
  }

  static String colorAccessibilityLabel(
    int colorValue, {
    required bool isVi,
  }) {
    return switch (colorValue) {
      0xFF0D7C66 => isVi ? 'Xanh ngọc bích' : 'Jade green',
      0xFF1D5BD6 => isVi ? 'Xanh dương đậm' : 'Cobalt blue',
      0xFFC0352B => isVi ? 'Đỏ son' : 'Vermilion red',
      0xFFD97706 => isVi ? 'Vàng hổ phách' : 'Amber',
      0xFF7C3AED => isVi ? 'Tím diên vĩ' : 'Iris purple',
      0xFFDB2777 => isVi ? 'Hồng đậm' : 'Berry pink',
      0xFF0891B2 => isVi ? 'Xanh lam' : 'Cyan',
      0xFF4F46E5 => isVi ? 'Xanh chàm' : 'Indigo',
      0xFF15803D => isVi ? 'Xanh lá rừng' : 'Forest green',
      0xFFB45309 => isVi ? 'Nâu đất nung' : 'Terracotta',
      0xFF334155 => isVi ? 'Xám đá' : 'Slate',
      0xFF9333EA => isVi ? 'Tím mận' : 'Plum',
      0xFF0284C7 => isVi ? 'Xanh biển' : 'Sky blue',
      0xFFE11D48 => isVi ? 'Đỏ hồng' : 'Crimson rose',
      _ => isVi ? 'Màu tùy chỉnh' : 'Custom color',
    };
  }

  /// Curated high-contrast palette for categories and wallets.
  static const List<int> palette = [
    0xFF0D7C66, // Jade
    0xFF1D5BD6, // Cobalt
    0xFFC0352B, // Vermilion
    0xFFD97706, // Amber
    0xFF7C3AED, // Iris
    0xFFDB2777, // Berry
    0xFF0891B2, // Cyan
    0xFF4F46E5, // Indigo
    0xFF15803D, // Forest
    0xFFB45309, // Terracotta
    0xFF334155, // Slate
    0xFF9333EA, // Plum
    0xFF0284C7, // Sky blue
    0xFFE11D48, // Crimson rose
  ];
}
