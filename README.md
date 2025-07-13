# Rootly AI Suggestions

An intelligent incident response assistant that analyzes meeting transcripts in real-time and provides actionable suggestions for incident management. The system replays incident transcripts at 10x speed (10 minutes compressed to 1 minute) while generating AI-powered suggestions for action items, trigger events, root cause theories, and missing metadata.

## How It Works

### Architecture Overview

The application uses a sophisticated two-tier processing pipeline to achieve sub-second response times:

**Tier 1: Heuristic Filter (<50ms)**
- Fast regex-based pattern matching for common incident scenarios
- Filters out irrelevant messages to reduce AI processing load
- Immediate response to user interactions

**Tier 2: AI Analysis (Background)**
- Advanced language model analysis using OpenAI's API
- Function calling for structured JSON output
- Context-aware processing using the last 8 messages
- Confidence scoring with logprob integration

### Real-Time Processing Flow

1. **Transcript Replay**: Messages display every ~750ms during replay
2. **Heuristic Filtering**: Each message passes through regex filters
3. **Background Processing**: Qualifying messages are queued for AI analysis
4. **AI Analysis**: Language model analyzes context and generates suggestions
5. **Deduplication**: SHA-256 content hashing prevents duplicate suggestions
6. **Real-Time Updates**: WebSocket broadcasts deliver suggestions to the browser
7. **Interactive UI**: Users can provide feedback, accept suggestions, and export reports

### Key Features

**Smart Categorization**
- 📝 Action Items: Tasks to complete post-incident
- 🚨 Trigger Events: Timeline milestones and status changes
- 🧠 Root Cause Theories: Potential causes identified during investigation
- 📊 Missing Metadata: Information gaps that should be documented

**Advanced Deduplication**
- SHA-256 content hashing for exact duplicate detection
- Similarity analysis with confidence penalties
- Duplicate count badges for repeated suggestions

**Production-Ready Features**
- "Add to Record" action for accepting suggestions
- Context display showing conversation flow
- Jump-to-source functionality for tracing suggestions
- Export functionality for incident reports
- Confidence filtering with realistic scoring (50-95%)

**Performance Optimizations**
- Sidekiq background job processing
- Redis-backed ActionCable for WebSocket communication
- Database reset on startup for fresh replay sessions
- Optimized heuristic patterns for timeline events

## Technology Stack

- **Backend**: Ruby on Rails 8.0.2
- **Database**: SQLite with Active Record
- **Background Jobs**: Sidekiq with Redis
- **Real-Time Communication**: ActionCable WebSockets
- **AI Integration**: OpenAI API with function calling
- **Frontend**: Vanilla JavaScript with modern CSS
- **Deployment**: Docker-ready with Kamal configuration

## How to Run

### Prerequisites

1. **Ruby**: Version 2.6+ (check with `ruby -v`)
2. **Bundler**: Install with `gem install bundler`
3. **Redis**: Required for Sidekiq and ActionCable
4. **OpenAI API Key**: For AI suggestion generation

### Installation Steps

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd rootly_ai_suggestions
   bundle install
   ```

2. **Environment Configuration**
   Create a `.env` file in the root directory:
   ```bash
   OPENAI_API_KEY=your_openai_api_key_here
   REDIS_URL=redis://localhost:6379/0
   ```

3. **Database Setup**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start Redis Server**
   ```bash
   redis-server
   ```

5. **Start Sidekiq Worker** (in a separate terminal)
   ```bash
   bundle exec sidekiq
   ```

6. **Start Rails Server** (in another terminal)
   ```bash
   rails server
   ```

7. **Access Application**
   Open your browser to `http://localhost:3000`

### Development Workflow

**Starting the Application**
```bash
# Terminal 1: Redis
redis-server

# Terminal 2: Sidekiq
bundle exec sidekiq

# Terminal 3: Rails
rails server
```

**Monitoring**
- **Application**: `http://localhost:3000`
- **Sidekiq Dashboard**: `http://localhost:3000/sidekiq`
- **Logs**: Check `log/development.log` for detailed processing information

### Usage Instructions

1. **Start Replay**: Click "Start Replay" to begin transcript playback
2. **Watch Suggestions**: AI suggestions appear in real-time on the right panel
3. **Accept Suggestions**: Click "Add to Record" to mark suggestions as accepted
4. **View Context**: Click "Context" to see conversation flow leading to suggestions
5. **Jump to Source**: Click suggestion cards to highlight the triggering message
6. **Export Report**: Use "Export Accepted" to download a markdown summary
7. **Stop Replay**: Click "Stop Replay" to halt processing and reset the session

### Configuration Options

**Confidence Filtering**
Adjust the confidence threshold in the UI dropdown (50%+ to 90%+) to filter suggestions based on AI confidence scores.


### Troubleshooting

**Common Issues**

1. **Suggestions Not Appearing**
   - Check Redis connection: `redis-cli ping`
   - Verify Sidekiq is running: `bundle exec sidekiq`
   - Check OpenAI API key in `.env` file

2. **WebSocket Connection Failed**
   - Ensure ActionCable is properly configured
   - Check browser console for connection errors
   - Verify Redis is accessible

3. **Database Errors**
   - Run `rails db:migrate` to apply latest schema changes
   - Check that incident record exists: `rails console` → `Incident.first`

4. **Performance Issues**
   - Monitor Sidekiq dashboard for queue backlogs
   - Adjust concurrency settings in `config/initializers/sidekiq.rb`
   - Check OpenAI API rate limits

### Development Notes

**Database Schema**
The application uses several key models:
- `Incident`: Container for incident sessions
- `Suggestion`: AI-generated recommendations with metadata
- Content deduplication via SHA-256 hashing
- Confidence scoring and feedback tracking

**Background Processing**
Sidekiq handles AI processing asynchronously to maintain responsive UI. The `Llms::SuggestJob` processes messages with context awareness and broadcasts results via ActionCable.

**Real-Time Communication**
ActionCable channels provide bidirectional communication between the Rails backend and JavaScript frontend, enabling real-time suggestion delivery without page refreshes.

## Production Deployment

The application includes Docker configuration and Kamal deployment setup for production environments. Ensure proper environment variables, database connections, and Redis scaling for production workloads.

## Contributing

This application demonstrates modern Rails patterns including background job processing, real-time communication, and AI integration. The codebase emphasizes performance, reliability, and user experience in incident response scenarios.
