import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import '../service/apiQuran.dart';
import '../service/bookmark_service.dart';
import '../main.dart';
import 'ayah_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  QuranScreenState createState() => QuranScreenState();
}

class QuranScreenState extends State<QuranScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final BookmarkService _bookmarkService = BookmarkService();
  List<dynamic> _allSurahs = [];
  List<dynamic> _filteredSurahs = [];
  Map<String, dynamic>? _lastRead;
  late AnimationController _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLastRead(); // Memuat ulang data bookmark
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSurahs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final surahs = await ApiQuran().getSurah();
      setState(() {
        _allSurahs = surahs;
        _filteredSurahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching surahs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSurahs(String query) {
    final filtered = _allSurahs.where((surah) {
      final number = surah['number'].toString();
      final englishName = surah['englishName'].toLowerCase();
      final name = surah['name'].toLowerCase();
      final translation = surah['englishNameTranslation'].toLowerCase();
      final searchQuery = query.toLowerCase();

      return number.contains(searchQuery) ||
          englishName.contains(searchQuery) ||
          name.contains(searchQuery) ||
          translation.contains(searchQuery);
    }).toList();

    setState(() {
      _filteredSurahs = filtered;
    });
  }

  Future<void> _loadLastRead() async {
    final lastRead = await _bookmarkService.getLastRead();
    setState(() {
      _lastRead = lastRead;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          title: Text(
            "Al-Quran",
            style: TextStyle(
              color: theme.appBarTheme.titleTextStyle?.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  if (isDarkMode) {
                    _animationController.reverse();
                  } else {
                    _animationController.forward();
                  }
                  themeProvider.toggleTheme();
                },
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: theme.appBarTheme.iconTheme?.color,
                          size: 26,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        )
            : Column(
          children: [
            if (_lastRead != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AyahScreen(
                        surahNumber: _lastRead!['surahNumber'],
                        surahName: _lastRead!['surahName'],
                        bookmarkedAyahNumber: _lastRead!['ayahNumber'],
                      ),
                    ),
                  ).then((_) {
                    _loadLastRead();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? colorScheme.primary.withOpacity(0.15)
                        : colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bookmark,
                            color: isDarkMode ? Colors.white : Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Continue Reading',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? colorScheme.tertiary
                                      : colorScheme.tertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Surah: ${_lastRead!['surahName']} (${_lastRead!['surahNumber']})',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.tertiary.withOpacity(0.8)
                                      : colorScheme.tertiary.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                'Ayah: ${_lastRead!['ayahNumber']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.tertiary.withOpacity(0.8)
                                      : colorScheme.tertiary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? colorScheme.surface.withOpacity(0.8)
                      : colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSurahs,
                  style: TextStyle(
                    color: isDarkMode
                        ? colorScheme.tertiary
                        : colorScheme.tertiary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search surah...',
                    hintStyle: TextStyle(
                      color: isDarkMode
                          ? colorScheme.tertiary.withOpacity(0.6)
                          : colorScheme.tertiary.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 20.0
                    ),
                  ),
                ),
              ),
            ),
            // Surah List
            Expanded(
              child: _filteredSurahs.isEmpty
                  ? Center(
                child: Text(
                  'No Surah found',
                  style: TextStyle(
                    color: isDarkMode
                        ? colorScheme.tertiary
                        : colorScheme.tertiary,
                    fontSize: 18,
                  ),
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _filteredSurahs.length,
                itemBuilder: (context, index) {
                  final surah = _filteredSurahs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? colorScheme.surface.withOpacity(0.4)
                          : colorScheme.surface.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AyahScreen(
                                surahNumber: surah['number'],
                                surahName: surah['englishName'],
                              ),
                            ),
                          ).then((_) {
                            _loadLastRead();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    surah['number'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      surah['englishName'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? colorScheme.tertiary
                                            : colorScheme.tertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      surah['englishNameTranslation'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? colorScheme.tertiary.withOpacity(0.7)
                                            : colorScheme.tertiary.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      '${surah['numberOfAyahs']} ayah',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? colorScheme.tertiary.withOpacity(0.6)
                                            : colorScheme.tertiary.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                surah['name'].replaceAll('سُورَةُ ', ''),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'AlQuran',
                                  color: isDarkMode
                                      ? colorScheme.primary
                                      : colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}