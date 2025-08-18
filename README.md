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
   cd ai_suggestions
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

# AI Suggestions

AI Suggestions is a real-time incident response assistant designed to analyze meeting transcripts and surface actionable insights for engineering teams. It uses a hybrid system of fast heuristics and OpenAI-powered language analysis to categorize, filter, and present key information — all while the transcript replays at 10x speed.

## 🔍 What It Does

- Replays incident call transcripts at 10x speed (10 minutes → 1 minute)
- Analyzes messages in real time and generates suggestions in four categories:
  - 📝 **Action Items**: Follow-ups and to-dos
  - 🚨 **Trigger Events**: Key timeline events (e.g. “rollback started”)
  - 🧠 **Root Cause Theories**: Hypotheses on the incident’s cause
  - 📊 **Missing Metadata**: Info gaps that need to be filled

Users can:
- View suggestion context
- Accept suggestions into the incident record
- Jump to the source message
- Filter by confidence level
- Export accepted suggestions as a Markdown report

## 🧠 How It Works

### Two-Tier Processing Pipeline

**Tier 1: Heuristic Filter (<50ms per message)**
- Uses fast, compiled regex patterns to detect common incident phrases (e.g., "rollback started")
- Instantly surfaces timeline events
- Filters out noise and reduces OpenAI API calls by ~70%

**Tier 2: AI Analysis (Background)**
- Qualifying messages are sent to a Sidekiq background job
- OpenAI function calling with structured JSON response
- Context-aware analysis (last 8 messages)
- Confidence scoring using logprob integration

### Real-Time Flow

1. User clicks **Start Replay**
2. Each transcript message is shown ~750ms apart
3. Message passes through `HeuristicFilter`
4. If eligible, it’s enqueued for `SuggestJob` and analyzed by OpenAI
5. Suggestions are streamed to the browser instantly using ActionCable
6. SHA-256 deduplication prevents duplicates; similar suggestions are scored lower
7. Users interact with the suggestion cards (view context, accept, jump to source, export)

## 🖥️ Key Features

- Real-time AI suggestions with WebSocket updates
- 4 suggestion categories with clear visual badges
- SHA-256 hashing + similarity penalty to prevent duplicates
- Confidence-based filtering (e.g., show only ≥80% confident suggestions)
- Markdown export for accepted items
- "Add to Record" action to build the incident report live
- Context and jump-to-source features for traceability

## ⚙️ Technology Stack

| Layer              | Tech Used                         |
|--------------------|-----------------------------------|
| **Backend**        | Ruby on Rails 8.0.2               |
| **Database**       | SQLite with ActiveRecord          |
| **AI Integration** | OpenAI API + function calling     |
| **Async Jobs**     | Sidekiq + Redis                   |
| **Real-Time**      | ActionCable WebSockets            |
| **Frontend**       | Vanilla JavaScript + CSS          |
| **Deployment**     | Docker-ready + Kamal config       |

## 💡 Design Decisions

- **Hybrid pipeline**: I chose to combine regex-based heuristics with AI analysis to balance speed and intelligence. This gives users immediate, high-precision feedback without overloading the AI layer.
- **Deduplication via hashing**: Suggestions are hashed using SHA-256 for exact-match detection. A similarity function penalizes near-duplicates, keeping the UI clean and reducing noise.
- **Context-aware analysis**: Rather than analyzing each message in isolation, the AI considers the last 8 messages to make informed suggestions — this reduces hallucinations and improves accuracy.
- **WebSocket delivery**: Using ActionCable for suggestion delivery means users see results *instantly*, without page reloads or polling.

## ⏳ Time Investment

I spent approximately **8 hours** on this project across 3 days
The first 3 hours were spent just getting familiar with ruby for the first time
Then the next 4 were spent just trying to get a working barebone mvp working
The last hour was spent fixing ui and small bugs

## 🚀 What I'd Add With More Time

1. **Machine learning-powered heuristics**  
   Train a lightweight model to learn incident patterns beyond regex, improving recall without sacrificing speed.

2. **Multi-tenant incident type support**  
   Allow customization for different use cases — e.g., security incidents vs infra vs customer escalations.
