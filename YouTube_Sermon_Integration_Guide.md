# YouTube Sermon Integration Implementation Guide

This guide provides a step-by-step approach to integrate YouTube sermon functionality into the AGBC app using a cached data strategy with YouTube Player Integration.

## Phase 1: Foundation Setup

### Step 1: Add Required Dependencies

**Purpose**: Install necessary packages for YouTube integration, HTTP requests, and caching.

Add these dependencies to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...

  # YouTube Integration
  youtube_player_flutter: ^9.0.1

  # HTTP and API
  http: ^1.1.0

  # Image Caching
  cached_network_image: ^3.3.1

  # JSON Handling
  json_annotation: ^4.8.1

  # Date/Time Utilities
  intl: ^0.19.0

dev_dependencies:
  # Existing dev dependencies...

  # Code Generation
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

**Why this step is important**: These packages provide the core functionality needed for YouTube video playback, API communication, image caching, and data serialization.

### Step 2: Environment Configuration

**Purpose**: Set up secure API key management for YouTube Data API.

Create/update `.env` file:

```env
# Existing environment variables...

# YouTube API Configuration
YOUTUBE_API_KEY=your_youtube_api_key_here
YOUTUBE_CHANNEL_ID=your_church_youtube_channel_id
```

Update `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Existing configuration...

  static String get youtubeApiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';
  static String get youtubeChannelId => dotenv.env['YOUTUBE_CHANNEL_ID'] ?? '';
}
```

**Why this step is important**: Keeps sensitive API credentials secure and allows for different configurations across development/production environments.

### Step 3: Database Schema Setup

**Purpose**: Create database tables to store sermon data and user interactions.

Execute these SQL commands in Supabase:

```sql
-- Sermons table for caching YouTube video data
CREATE TABLE sermons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  youtube_video_id VARCHAR(20) UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  published_at TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_seconds INTEGER,
  view_count BIGINT DEFAULT 0,
  tags TEXT[],
  series_id UUID REFERENCES sermon_series(id),
  is_featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sermon series for organizing content
CREATE TABLE sermon_series (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User sermon interactions for tracking progress
CREATE TABLE user_sermon_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  sermon_id UUID REFERENCES sermons(id) ON DELETE CASCADE,
  watch_progress_seconds INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  is_favorited BOOLEAN DEFAULT FALSE,
  last_watched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, sermon_id)
);

-- Indexes for performance
CREATE INDEX idx_sermons_published_at ON sermons(published_at DESC);
CREATE INDEX idx_sermons_series_id ON sermons(series_id);
CREATE INDEX idx_user_interactions_user_id ON user_sermon_interactions(user_id);
CREATE INDEX idx_user_interactions_sermon_id ON user_sermon_interactions(sermon_id);
```

**Why this step is important**: Provides a structured way to cache YouTube data locally, reducing API calls and improving app performance while tracking user engagement.

## Phase 2: Data Models and Services

### Step 4: Create Data Models

**Purpose**: Define structured data models for sermons and related entities.

Create `lib/models/sermon_model.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'sermon_model.g.dart';

@JsonSerializable()
class SermonModel {
  final String id;
  final String youtubeVideoId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final DateTime publishedAt;
  final int? durationSeconds;
  final int viewCount;
  final List<String> tags;
  final String? seriesId;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  SermonModel({
    required this.id,
    required this.youtubeVideoId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.publishedAt,
    this.durationSeconds,
    this.viewCount = 0,
    this.tags = const [],
    this.seriesId,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SermonModel.fromJson(Map<String, dynamic> json) => _$SermonModelFromJson(json);
  Map<String, dynamic> toJson() => _$SermonModelToJson(this);

  // Helper getters
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeVideoId';
  String get formattedDuration => _formatDuration(durationSeconds);

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}

@JsonSerializable()
class SermonSeriesModel {
  final String id;
  final String name;
  final String? description;
  final String? thumbnailUrl;
  final DateTime createdAt;

  SermonSeriesModel({
    required this.id,
    required this.name,
    this.description,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory SermonSeriesModel.fromJson(Map<String, dynamic> json) => _$SermonSeriesModelFromJson(json);
  Map<String, dynamic> toJson() => _$SermonSeriesModelToJson(this);
}

@JsonSerializable()
class UserSermonInteraction {
  final String id;
  final String userId;
  final String sermonId;
  final int watchProgressSeconds;
  final bool isCompleted;
  final bool isFavorited;
  final DateTime lastWatchedAt;

  UserSermonInteraction({
    required this.id,
    required this.userId,
    required this.sermonId,
    this.watchProgressSeconds = 0,
    this.isCompleted = false,
    this.isFavorited = false,
    required this.lastWatchedAt,
  });

  factory UserSermonInteraction.fromJson(Map<String, dynamic> json) => _$UserSermonInteractionFromJson(json);
  Map<String, dynamic> toJson() => _$UserSermonInteractionToJson(this);
}
```

**Why this step is important**: Provides type-safe data structures that match the database schema and include helpful utility methods for formatting and display.

### Step 5: YouTube API Service

**Purpose**: Handle communication with YouTube Data API to fetch video information.

Create `lib/services/youtube_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/sermon_model.dart';

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  // Fetch videos from church channel
  Future<List<SermonModel>> fetchChannelVideos({
    int maxResults = 50,
    String? pageToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?'
            'key=${AppConfig.youtubeApiKey}&'
            'channelId=${AppConfig.youtubeChannelId}&'
            'part=snippet&'
            'order=date&'
            'type=video&'
            'maxResults=$maxResults'
            '${pageToken != null ? '&pageToken=$pageToken' : ''}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        // Get detailed video information
        final videoIds = items.map((item) => item['id']['videoId']).join(',');
        final detailedVideos = await _fetchVideoDetails(videoIds);

        return detailedVideos;
      } else {
        throw Exception('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching YouTube videos: $e');
    }
  }

  // Fetch detailed video information including duration
  Future<List<SermonModel>> _fetchVideoDetails(String videoIds) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/videos?'
          'key=${AppConfig.youtubeApiKey}&'
          'id=$videoIds&'
          'part=snippet,contentDetails,statistics'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'] ?? [];

      return items.map((item) {
        final snippet = item['snippet'];
        final contentDetails = item['contentDetails'];
        final statistics = item['statistics'];

        return SermonModel(
          id: '', // Will be set when saved to database
          youtubeVideoId: item['id'],
          title: snippet['title'],
          description: snippet['description'],
          thumbnailUrl: snippet['thumbnails']['high']['url'],
          publishedAt: DateTime.parse(snippet['publishedAt']),
          durationSeconds: _parseDuration(contentDetails['duration']),
          viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
          tags: List<String>.from(snippet['tags'] ?? []),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch video details');
    }
  }

  // Parse ISO 8601 duration format (PT4M13S) to seconds
  int _parseDuration(String duration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);

    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      return hours * 3600 + minutes * 60 + seconds;
    }

    return 0;
  }
}
```

**Why this step is important**: Provides a clean interface to interact with YouTube's API, handles data transformation, and includes error handling for robust operation.

### Step 6: Sermon Data Service

**Purpose**: Manage local caching and database operations for sermon data.

Create `lib/services/sermon_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sermon_model.dart';
import 'youtube_service.dart';

class SermonService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final YouTubeService _youtubeService = YouTubeService();

  // Sync sermons from YouTube to local database
  Future<void> syncSermons() async {
    try {
      final youtubeVideos = await _youtubeService.fetchChannelVideos();

      for (final video in youtubeVideos) {
        await _upsertSermon(video);
      }
    } catch (e) {
      throw Exception('Failed to sync sermons: $e');
    }
  }

  // Insert or update sermon in database
  Future<void> _upsertSermon(SermonModel sermon) async {
    await _supabase.from('sermons').upsert({
      'youtube_video_id': sermon.youtubeVideoId,
      'title': sermon.title,
      'description': sermon.description,
      'thumbnail_url': sermon.thumbnailUrl,
      'published_at': sermon.publishedAt.toIso8601String(),
      'duration_seconds': sermon.durationSeconds,
      'view_count': sermon.viewCount,
      'tags': sermon.tags,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'youtube_video_id');
  }

  // Get cached sermons from database
  Future<List<SermonModel>> getCachedSermons({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('sermons')
        .select()
        .order('published_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => SermonModel.fromJson(json))
        .toList();
  }

  // Get featured sermons
  Future<List<SermonModel>> getFeaturedSermons() async {
    final response = await _supabase
        .from('sermons')
        .select()
        .eq('is_featured', true)
        .order('published_at', ascending: false)
        .limit(5);

    return (response as List)
        .map((json) => SermonModel.fromJson(json))
        .toList();
  }

  // Search sermons
  Future<List<SermonModel>> searchSermons(String query) async {
    final response = await _supabase
        .from('sermons')
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('published_at', ascending: false);

    return (response as List)
        .map((json) => SermonModel.fromJson(json))
        .toList();
  }

  // Update user interaction
  Future<void> updateUserInteraction({
    required String sermonId,
    int? watchProgressSeconds,
    bool? isCompleted,
    bool? isFavorited,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{
      'user_id': userId,
      'sermon_id': sermonId,
      'last_watched_at': DateTime.now().toIso8601String(),
    };

    if (watchProgressSeconds != null) {
      updates['watch_progress_seconds'] = watchProgressSeconds;
    }
    if (isCompleted != null) {
      updates['is_completed'] = isCompleted;
    }
    if (isFavorited != null) {
      updates['is_favorited'] = isFavorited;
    }

    await _supabase.from('user_sermon_interactions').upsert(
      updates,
      onConflict: 'user_id,sermon_id',
    );
  }

  // Get user's sermon interactions
  Future<List<UserSermonInteraction>> getUserInteractions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_sermon_interactions')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((json) => UserSermonInteraction.fromJson(json))
        .toList();
  }
}
```

**Why this step is important**: Provides a centralized service for managing sermon data, implements caching strategy to reduce API calls, and handles user interaction tracking.

## Phase 3: UI Implementation

### Step 7: Sermon Card Widget

**Purpose**: Create a reusable widget to display sermon information consistently.

Create `lib/widgets/sermon_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/sermon_model.dart';
import '../utils/theme.dart';

class SermonCard extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback? onTap;
  final bool showProgress;
  final double? watchProgress; // 0.0 to 1.0

  const SermonCard({
    Key? key,
    required this.sermon,
    this.onTap,
    this.showProgress = false,
    this.watchProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: sermon.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Duration badge
                if (sermon.formattedDuration.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sermon.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Progress bar
            if (showProgress && watchProgress != null)
              LinearProgressIndicator(
                value: watchProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sermon.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (sermon.description != null)
                    Text(
                      sermon.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(sermon.publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      if (sermon.viewCount > 0) ...[
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatViewCount(sermon.viewCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatViewCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
```

**Why this step is important**: Provides a consistent, attractive UI component for displaying sermons with thumbnail, metadata, and progress tracking capabilities.

### Step 8: Sermon Player Screen

**Purpose**: Create a dedicated screen for playing YouTube sermons with full controls and interaction tracking.

Create `lib/screens/sermon_player_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/sermon_model.dart';
import '../services/sermon_service.dart';
import '../widgets/custom_back_button.dart';

class SermonPlayerScreen extends StatefulWidget {
  final SermonModel sermon;

  const SermonPlayerScreen({
    Key? key,
    required this.sermon,
  }) : super(key: key);

  @override
  State<SermonPlayerScreen> createState() => _SermonPlayerScreenState();
}

class _SermonPlayerScreenState extends State<SermonPlayerScreen> {
  late YoutubePlayerController _controller;
  final SermonService _sermonService = SermonService();
  bool _isPlayerReady = false;
  bool _isFavorited = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadUserInteraction();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.sermon.youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'en',
        forceHD: false,
        loop: false,
      ),
    );

    _controller.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
        _totalDuration = _controller.metadata.duration;
      });
    }

    if (_controller.value.isPlaying) {
      setState(() {
        _currentPosition = _controller.value.position;
      });

      // Update watch progress every 10 seconds
      if (_currentPosition.inSeconds % 10 == 0) {
        _updateWatchProgress();
      }
    }
  }

  Future<void> _loadUserInteraction() async {
    try {
      final interactions = await _sermonService.getUserInteractions();
      final interaction = interactions.firstWhere(
        (i) => i.sermonId == widget.sermon.id,
        orElse: () => UserSermonInteraction(
          id: '',
          userId: '',
          sermonId: widget.sermon.id,
          lastWatchedAt: DateTime.now(),
        ),
      );

      setState(() {
        _isFavorited = interaction.isFavorited;
      });

      // Resume from last position if available
      if (interaction.watchProgressSeconds > 0) {
        _controller.seekTo(Duration(seconds: interaction.watchProgressSeconds));
      }
    } catch (e) {
      print('Error loading user interaction: $e');
    }
  }

  Future<void> _updateWatchProgress() async {
    try {
      final isCompleted = _currentPosition.inSeconds >= (_totalDuration.inSeconds * 0.9);

      await _sermonService.updateUserInteraction(
        sermonId: widget.sermon.id,
        watchProgressSeconds: _currentPosition.inSeconds,
        isCompleted: isCompleted,
      );
    } catch (e) {
      print('Error updating watch progress: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final newFavoriteStatus = !_isFavorited;
      await _sermonService.updateUserInteraction(
        sermonId: widget.sermon.id,
        isFavorited: newFavoriteStatus,
      );

      setState(() {
        _isFavorited = newFavoriteStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newFavoriteStatus ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  @override
  void dispose() {
    _updateWatchProgress(); // Save final progress
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Player section
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Theme.of(context).primaryColor,
              topActions: [
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    widget.sermon.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30.0,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              bottomActions: [
                CurrentPosition(),
                const SizedBox(width: 10.0),
                ProgressBar(isExpanded: true),
                const SizedBox(width: 10.0),
                RemainingDuration(),
                FullScreenButton(),
              ],
            ),

            // Sermon details section
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.sermon.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(widget.sermon.publishedAt),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (widget.sermon.viewCount > 0) ...[
                                      Icon(
                                        Icons.visibility,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.sermon.viewCount} views',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              _isFavorited ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorited ? Colors.red : Colors.grey,
                              size: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Share functionality
                              // You can implement sharing here
                            },
                            icon: const Icon(
                              Icons.share,
                              color: Colors.grey,
                              size: 28,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      if (widget.sermon.description != null) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.sermon.description!,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],

                      // Tags
                      if (widget.sermon.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.sermon.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
```

**Why this step is important**: Provides a full-featured video player experience with progress tracking, favorites, and detailed sermon information display.

### Step 9: Sermons Library Screen

**Purpose**: Create a comprehensive screen for browsing all available sermons with search and filtering.

Create `lib/screens/sermons_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/sermon_model.dart';
import '../services/sermon_service.dart';
import '../widgets/sermon_card.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/loading_indicator.dart';
import 'sermon_player_screen.dart';

class SermonsScreen extends StatefulWidget {
  const SermonsScreen({Key? key}) : super(key: key);

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends State<SermonsScreen> {
  final SermonService _sermonService = SermonService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SermonModel> _sermons = [];
  List<UserSermonInteraction> _userInteractions = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadSermons();
    _loadUserInteractions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isSearching) {
        _loadMoreSermons();
      }
    }
  }

  Future<void> _loadSermons() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final sermons = await _sermonService.getCachedSermons(
        limit: _pageSize,
        offset: 0,
      );

      setState(() {
        _sermons = sermons;
        _currentPage = 0;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load sermons: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreSermons() async {
    if (_isLoading || _isSearching) return;

    setState(() => _isLoading = true);

    try {
      final newSermons = await _sermonService.getCachedSermons(
        limit: _pageSize,
        offset: (_currentPage + 1) * _pageSize,
      );

      if (newSermons.isNotEmpty) {
        setState(() {
          _sermons.addAll(newSermons);
          _currentPage++;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load more sermons: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserInteractions() async {
    try {
      final interactions = await _sermonService.getUserInteractions();
      setState(() => _userInteractions = interactions);
    } catch (e) {
      print('Error loading user interactions: $e');
    }
  }

  Future<void> _searchSermons(String query) async {
    if (query.isEmpty) {
      _loadSermons();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final searchResults = await _sermonService.searchSermons(query);
      setState(() => _sermons = searchResults);
    } catch (e) {
      _showErrorSnackBar('Search failed: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _refreshSermons() async {
    try {
      await _sermonService.syncSermons();
      await _loadSermons();
      await _loadUserInteractions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sermons updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to refresh sermons: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  UserSermonInteraction? _getUserInteraction(String sermonId) {
    try {
      return _userInteractions.firstWhere((i) => i.sermonId == sermonId);
    } catch (e) {
      return null;
    }
  }

  double? _getWatchProgress(String sermonId, int? durationSeconds) {
    final interaction = _getUserInteraction(sermonId);
    if (interaction == null || durationSeconds == null || durationSeconds == 0) {
      return null;
    }
    return interaction.watchProgressSeconds / durationSeconds;
  }

  void _playSermon(SermonModel sermon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SermonPlayerScreen(sermon: sermon),
      ),
    ).then((_) {
      // Refresh user interactions when returning from player
      _loadUserInteractions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sermons'),
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            onPressed: _refreshSermons,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sermons...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchSermons('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchSermons(value);
                  }
                });
              },
            ),
          ),

          // Sermons list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshSermons,
              child: _sermons.isEmpty && !_isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No sermons found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _sermons.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _sermons.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final sermon = _sermons[index];
                        final watchProgress = _getWatchProgress(
                          sermon.id,
                          sermon.durationSeconds,
                        );

                        return SermonCard(
                          sermon: sermon,
                          onTap: () => _playSermon(sermon),
                          showProgress: watchProgress != null,
                          watchProgress: watchProgress,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Why this step is important**: Provides a comprehensive browsing experience with search, infinite scrolling, progress tracking, and refresh capabilities.

### Step 10: Navigation and Routing Setup

**Purpose**: Add the necessary routes and navigation for sermon functionality.

Update `lib/main.dart` to include sermon routes:

```dart
// In the MaterialApp widget, update the routes section:
routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const MainNavigationScreen(),
  '/meetings': (context) => const MeetingsScreen(),
  // Add sermon routes
  '/sermons': (context) => const SermonsScreen(),
  '/sermon-player': (context) {
    final sermon = ModalRoute.of(context)!.settings.arguments as SermonModel;
    return SermonPlayerScreen(sermon: sermon);
  },
},
```

**Why this step is important**: Enables proper navigation between screens and ensures sermon functionality is accessible throughout the app.

### Step 11: Home Screen Integration

**Purpose**: Add sermon section to the existing home screen.

Update `lib/screens/home_screen.dart` to include sermons section:

```dart
// Add these imports at the top
import '../services/sermon_service.dart';
import '../widgets/sermon_card.dart';

// Add this to the existing home screen class
class _HomeScreenState extends State<HomeScreen> {
  // Existing variables...
  final SermonService _sermonService = SermonService();
  List<SermonModel> _featuredSermons = [];
  bool _isLoadingSermons = false;

  @override
  void initState() {
    super.initState();
    // Existing initialization...
    _loadFeaturedSermons();
  }

  Future<void> _loadFeaturedSermons() async {
    setState(() => _isLoadingSermons = true);
    try {
      final sermons = await _sermonService.getFeaturedSermons();
      setState(() => _featuredSermons = sermons);
    } catch (e) {
      // Handle error
      print('Error loading sermons: $e');
    } finally {
      setState(() => _isLoadingSermons = false);
    }
  }

  // Add this method to build the sermons section
  Widget _buildSermonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Sermons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/sermons');
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingSermons)
          const Center(child: CircularProgressIndicator())
        else if (_featuredSermons.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No sermons available'),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _featuredSermons.length,
              itemBuilder: (context, index) {
                final sermon = _featuredSermons[index];
                return SizedBox(
                  width: 300,
                  child: SermonCard(
                    sermon: sermon,
                    onTap: () => _playSermon(sermon),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _playSermon(SermonModel sermon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SermonPlayerScreen(sermon: sermon),
      ),
    );
  }

  // Update the existing build method to include the sermons section
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Existing scaffold content...
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Existing sections...
            _buildSermonsSection(),
            const SizedBox(height: 24),
            // Other existing sections...
          ],
        ),
      ),
    );
  }
}
```

**Why this step is important**: Integrates sermon functionality into the main user flow, providing easy access to recent sermons from the home screen.

## Phase 4: Background Sync and Performance

### Step 12: Background Sync Setup

**Purpose**: Implement automatic syncing of sermon data to keep content fresh.

Create `lib/services/background_sync_service.dart`:

```dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'sermon_service.dart';

class BackgroundSyncService {
  static const String _lastSyncKey = 'last_sermon_sync';
  static const Duration _syncInterval = Duration(hours: 6);

  final SermonService _sermonService = SermonService();
  Timer? _syncTimer;

  // Initialize background sync
  void initialize() {
    _scheduleNextSync();
  }

  // Schedule the next sync based on last sync time
  void _scheduleNextSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);

    DateTime nextSyncTime;
    if (lastSyncString != null) {
      final lastSync = DateTime.parse(lastSyncString);
      nextSyncTime = lastSync.add(_syncInterval);
    } else {
      nextSyncTime = DateTime.now();
    }

    final now = DateTime.now();
    final delay = nextSyncTime.isAfter(now)
        ? nextSyncTime.difference(now)
        : Duration.zero;

    _syncTimer?.cancel();
    _syncTimer = Timer(delay, () {
      _performSync();
      _scheduleNextSync();
    });
  }

  // Perform the actual sync
  Future<void> _performSync() async {
    try {
      await _sermonService.syncSermons();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      print('Sermon sync completed successfully');
    } catch (e) {
      print('Sermon sync failed: $e');
      // Retry after shorter interval on failure
      _syncTimer?.cancel();
      _syncTimer = Timer(const Duration(minutes: 30), () {
        _performSync();
        _scheduleNextSync();
      });
    }
  }

  // Manual sync trigger
  Future<void> forceSync() async {
    _syncTimer?.cancel();
    await _performSync();
    _scheduleNextSync();
  }

  // Cleanup
  void dispose() {
    _syncTimer?.cancel();
  }
}
```

**Why this step is important**: Ensures sermon content stays up-to-date automatically without user intervention, improving user experience and reducing manual maintenance.

### Step 13: Performance Optimization

**Purpose**: Implement caching and optimization strategies for smooth performance.

Create `lib/utils/sermon_cache_manager.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/sermon_model.dart';

class SermonCacheManager {
  static const String _cachePrefix = 'sermon_cache_';
  static const Duration _cacheExpiry = Duration(hours: 24);

  // Cache sermon list
  static Future<void> cacheSermons(String key, List<SermonModel> sermons) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': sermons.map((s) => s.toJson()).toList(),
    };
    await prefs.setString('$_cachePrefix$key', json.encode(cacheData));
  }

  // Get cached sermons
  static Future<List<SermonModel>?> getCachedSermons(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString('$_cachePrefix$key');

    if (cacheString == null) return null;

    try {
      final cacheData = json.decode(cacheString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        await prefs.remove('$_cachePrefix$key');
        return null;
      }

      final List<dynamic> data = cacheData['data'];
      return data.map((json) => SermonModel.fromJson(json)).toList();
    } catch (e) {
      // Invalid cache data, remove it
      await prefs.remove('$_cachePrefix$key');
      return null;
    }
  }

  // Clear all sermon cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
```

**Why this step is important**: Provides fast loading times by caching frequently accessed data locally, reducing network requests and improving user experience.

### Step 14: Initialize Background Sync in Main App

**Purpose**: Integrate background sync service into the main application lifecycle.

Update `lib/main.dart` to initialize background sync:

```dart
// Add import at the top
import 'services/background_sync_service.dart';

// In the main() function, after other service initializations:
Future<void> main() async {
  // ... existing initialization code ...

  // Initialize services
  final authService = AuthService();
  final notificationService = NotificationService();
  final backgroundSyncService = BackgroundSyncService(); // Add this

  // Initialize services in sequence
  await authService.initialize();
  await notificationService.initialize();
  backgroundSyncService.initialize(); // Add this

  // ... rest of the main function ...
}
```

**Why this step is important**: Ensures background sync starts automatically when the app launches and keeps sermon content updated.

## Implementation Summary

This comprehensive implementation guide provides a complete solution for integrating YouTube sermon functionality with the following key components:

### Technical Benefits

- **Complete YouTube Integration**: Full video player with controls and progress tracking
- **Cached Data Strategy**: Reduces API calls and improves performance
- **Type-Safe Models**: Prevents runtime errors with structured data
- **Background Sync**: Keeps content fresh automatically
- **User Interaction Tracking**: Enables personalized experiences with favorites and progress
- **Performance Optimization**: Fast loading with local caching
- **Search Functionality**: Easy content discovery with real-time search
- **Comprehensive Navigation**: Proper routing and screen transitions

### User Experience Benefits

- **Seamless Integration**: Sermons appear naturally in the home screen
- **Full-Featured Player**: Professional video player with YouTube controls
- **Progress Tracking**: Users can resume where they left off
- **Favorites System**: Users can bookmark their favorite sermons
- **Consistent UI**: Reusable components maintain design consistency
- **Offline-Ready**: Cached data works without internet
- **Search and Browse**: Easy content discovery and navigation

### Maintenance Benefits

- **Modular Architecture**: Easy to extend and modify
- **Error Handling**: Robust error management throughout
- **Configuration Management**: Secure API key handling
- **Database Schema**: Structured data storage with proper indexing
- **Background Updates**: Automatic content synchronization

This implementation ensures users can seamlessly listen to any sermon from your YouTube channel directly within the app, with a professional, feature-rich experience that rivals dedicated video streaming applications.
