import Foundation

struct OfflinePrompts {

    static func getPrompt(mood: Mood, activities: [Activity], timeOfDay: TimeOfDay = .current) -> String {
        // Try time-specific prompts for morning/night
        if let timePrompt = getTimeSpecificPrompt(mood: mood, timeOfDay: timeOfDay) {
            return timePrompt
        }

        guard let activity = activities.first else {
            return moodOnlyPrompts[mood]?.randomElement() ?? generalPrompts.randomElement()!
        }

        // Try mood + activity combo
        let key = "\(mood.rawValue)_\(activity.rawValue)"
        if let prompt = moodActivityPrompts[key]?.randomElement() {
            return prompt
        }

        // Fall back to mood-only prompts
        return moodOnlyPrompts[mood]?.randomElement() ?? generalPrompts.randomElement()!
    }

    private static func getTimeSpecificPrompt(mood: Mood, timeOfDay: TimeOfDay) -> String? {
        // Only use time-specific prompts sometimes (30% chance)
        guard Int.random(in: 1...10) <= 3 else { return nil }

        switch timeOfDay {
        case .earlyMorning, .morning:
            return morningPrompts[mood]?.randomElement()
        case .evening, .night:
            return eveningPrompts[mood]?.randomElement()
        case .afternoon:
            return nil // Use activity-based prompts for afternoon
        }
    }

    // MARK: - Morning prompts

    private static let morningPrompts: [Mood: [String]] = [
        .great: ["What are you excited about today?", "What's making this morning feel good?"],
        .good: ["What do you want to make happen today?", "What are you looking forward to?"],
        .okay: ["What would make today a win?", "What's one thing you want to focus on?"],
        .low: ["What's heavy on your mind this morning?", "What do you need today?"],
        .stressed: ["What's already weighing on you?", "What can you let go of before the day starts?"],
        .anxious: ["What's making you nervous about today?", "What would help you feel ready?"],
        .calm: ["How can you protect this peace today?", "What are you grateful for this morning?"],
        .energetic: ["What do you want to tackle first?", "Where will you put this energy?"],
        .tired: ["Did you sleep okay?", "What would help you feel more awake?"],
        .grateful: ["What are you thankful for this morning?", "Who will you appreciate today?"]
    ]

    // MARK: - Evening prompts

    private static let eveningPrompts: [Mood: [String]] = [
        .great: ["What made today so good?", "What moment do you want to remember?"],
        .good: ["What went well today?", "What are you proud of from today?"],
        .okay: ["What's one good thing from today?", "What could have been better?"],
        .low: ["What's bringing you down tonight?", "What do you need before bed?"],
        .stressed: ["What's still on your mind?", "What can you put down for tonight?"],
        .anxious: ["What's keeping you up?", "What would help you rest easier?"],
        .calm: ["What brought you peace today?", "What are you grateful for tonight?"],
        .energetic: ["What got you fired up today?", "How will you wind down?"],
        .tired: ["What wore you out?", "What rest do you need tonight?"],
        .grateful: ["What was the best part of today?", "Who made your day better?"]
    ]

    // MARK: - Mood + Activity specific prompts

    private static let moodActivityPrompts: [String: [String]] = [
        // WORK combinations
        "Great_Work": [
            "What win at work made you feel this good?",
            "Who did you enjoy working with today?",
            "What made work feel easy today?"
        ],
        "Good_Work": [
            "What went smoothly at work?",
            "What task did you nail today?",
            "What made work feel worthwhile?"
        ],
        "Stressed_Work": [
            "What's the biggest pressure at work right now?",
            "What would take one thing off your plate?",
            "What do you wish you could say to your boss?"
        ],
        "Tired_Work": [
            "What drained you the most at work?",
            "Is work taking too much from you?",
            "What would make work less exhausting?"
        ],
        "Anxious_Work": [
            "What's worrying you about work?",
            "What's the worst that could happen, really?",
            "What do you need to feel more secure at work?"
        ],
        "Low_Work": [
            "What's bringing you down about work?",
            "Do you feel seen at work?",
            "What would make work feel better?"
        ],

        // SOCIALIZING combinations
        "Great_Socializing": [
            "Who made you feel so happy?",
            "What moment with them was the best?",
            "What do you love about the people you saw?"
        ],
        "Good_Socializing": [
            "Who lifted your spirits today?",
            "What did you talk about that mattered?",
            "What made the time together nice?"
        ],
        "Low_Socializing": [
            "Did being with people help or make it harder?",
            "Did you feel understood?",
            "What do you wish someone had said to you?"
        ],
        "Anxious_Socializing": [
            "What made you nervous around others?",
            "Did you feel like yourself?",
            "What would have made you more comfortable?"
        ],
        "Tired_Socializing": [
            "Did being social drain or energize you?",
            "Do you need more alone time?",
            "Was it worth the energy?"
        ],

        // EXERCISE combinations
        "Great_Exercise": [
            "How did moving your body make you feel this good?",
            "What part of the workout felt amazing?",
            "What can your body do that makes you proud?"
        ],
        "Good_Exercise": [
            "How does your body feel after that?",
            "What pushed you to show up?",
            "What felt strong today?"
        ],
        "Tired_Exercise": [
            "Did you push too hard?",
            "What does your body need now?",
            "Was the tiredness worth it?"
        ],
        "Stressed_Exercise": [
            "Did exercise help with the stress?",
            "What are you trying to sweat out?",
            "How does your body hold your stress?"
        ],

        // FAMILY combinations
        "Great_Family": [
            "What moment with family made you so happy?",
            "Who do you appreciate most right now?",
            "What do you love about your family?"
        ],
        "Good_Family": [
            "What was nice about family time?",
            "Who made you laugh?",
            "What memory from today will you keep?"
        ],
        "Stressed_Family": [
            "What's causing tension at home?",
            "What do you wish your family understood?",
            "What would make home feel more peaceful?"
        ],
        "Low_Family": [
            "Do you feel supported by your family?",
            "What do you need from them right now?",
            "What's hard to say out loud?"
        ],

        // RELAXING combinations
        "Great_Relaxing": [
            "What made relaxing feel so good?",
            "How can you have more moments like this?",
            "What do you appreciate about today?"
        ],
        "Good_Relaxing": [
            "What helped you unwind?",
            "What does rest feel like right now?",
            "What do you need more of?"
        ],
        "Anxious_Relaxing": [
            "Is it hard to let yourself rest?",
            "What keeps running through your mind?",
            "What would help you actually relax?"
        ],
        "Stressed_Relaxing": [
            "Are you able to actually rest?",
            "What's stopping you from letting go?",
            "What do you need to put down?"
        ],

        // CREATIVITY combinations
        "Great_Creativity": [
            "What did you create that you're proud of?",
            "Where did your inspiration come from?",
            "What made creating feel so good?"
        ],
        "Good_Creativity": [
            "What did you make today?",
            "What part of creating felt best?",
            "What do you want to try next?"
        ],
        "Low_Creativity": [
            "Did creating help you process how you feel?",
            "What are you trying to express?",
            "What would you create if fear didn't exist?"
        ],

        // NATURE combinations
        "Great_Nature": [
            "What did you see outside that made you happy?",
            "How did nature lift your mood?",
            "What's beautiful about the world today?"
        ],
        "Good_Nature": [
            "What did you notice outside?",
            "How did fresh air make you feel?",
            "What sounds or smells stood out?"
        ],
        "Calm_Nature": [
            "What about nature brought you peace?",
            "How can you bring more of this into your life?",
            "What do you feel grateful for?"
        ],
        "Stressed_Nature": [
            "Did being outside help clear your head?",
            "What did nature remind you of?",
            "What do you need to let go of?"
        ],

        // MEDITATION combinations
        "Calm_Meditation": [
            "What thoughts came up during stillness?",
            "How does this peace feel?",
            "What are you grateful for right now?"
        ],
        "Anxious_Meditation": [
            "Was it hard to quiet your mind?",
            "What kept coming up?",
            "What do you need to feel safe?"
        ],
        "Stressed_Meditation": [
            "Did you find any relief?",
            "What are you carrying that's too heavy?",
            "What would help you feel lighter?"
        ]
    ]

    // MARK: - Mood-only prompts (fallback)

    private static let moodOnlyPrompts: [Mood: [String]] = [
        .great: [
            "What made today so good?",
            "Who do you want to tell about this feeling?",
            "What are you celebrating right now?"
        ],
        .good: [
            "What small thing made you smile?",
            "What went right today?",
            "What are you looking forward to?"
        ],
        .okay: [
            "What's one good thing from today?",
            "What would make tomorrow better?",
            "What do you need right now?"
        ],
        .low: [
            "What's weighing on you?",
            "What would help you feel better?",
            "What do you need to hear right now?"
        ],
        .stressed: [
            "What's the biggest thing on your mind?",
            "What can you control right now?",
            "What do you need to let go of?"
        ],
        .anxious: [
            "What's making you worry?",
            "What's one thing you know for sure?",
            "What would help you feel calmer?"
        ],
        .calm: [
            "What brought you this peace?",
            "What are you grateful for?",
            "How can you hold onto this feeling?"
        ],
        .energetic: [
            "What's exciting you right now?",
            "What do you want to do with this energy?",
            "What's making you feel so alive?"
        ],
        .tired: [
            "What wore you out today?",
            "What kind of rest do you need?",
            "What can wait until tomorrow?"
        ],
        .grateful: [
            "What are you most thankful for?",
            "Who made a difference in your life lately?",
            "What small thing brought you joy?"
        ]
    ]

    // MARK: - General fallback

    private static let generalPrompts = [
        "What's on your mind right now?",
        "How are you really feeling?",
        "What do you need to get off your chest?",
        "What mattered most about today?",
        "What would make tomorrow great?"
    ]

    // MARK: - Public accessors for library view

    static func getMoodPrompts(for mood: Mood) -> [String] {
        var prompts: [String] = []

        // Add mood-only prompts
        if let moodPrompts = moodOnlyPrompts[mood] {
            prompts.append(contentsOf: moodPrompts)
        }

        // Add morning prompts for this mood
        if let morning = morningPrompts[mood] {
            prompts.append(contentsOf: morning)
        }

        // Add evening prompts for this mood
        if let evening = eveningPrompts[mood] {
            prompts.append(contentsOf: evening)
        }

        // Add any mood+activity combo prompts
        for (key, values) in moodActivityPrompts {
            if key.hasPrefix(mood.rawValue + "_") {
                prompts.append(contentsOf: values)
            }
        }

        return Array(Set(prompts)).sorted()
    }

    static func getActivityPrompts(for activity: Activity) -> [String] {
        var prompts: [String] = []

        // Add any mood+activity combo prompts for this activity
        for (key, values) in moodActivityPrompts {
            if key.hasSuffix("_" + activity.rawValue) {
                prompts.append(contentsOf: values)
            }
        }

        return Array(Set(prompts)).sorted()
    }

    static func getRandomPrompt() -> String {
        // Collect all prompts from various sources
        var allPrompts: [String] = generalPrompts

        for prompts in moodOnlyPrompts.values {
            allPrompts.append(contentsOf: prompts)
        }

        for prompts in morningPrompts.values {
            allPrompts.append(contentsOf: prompts)
        }

        for prompts in eveningPrompts.values {
            allPrompts.append(contentsOf: prompts)
        }

        return allPrompts.randomElement() ?? "What's on your mind today?"
    }

    // MARK: - Evening Reflection Prompts (for daily review)

    static let eveningReflection: [String] = [
        "What was the highlight of your day?",
        "What's one thing you accomplished that you're proud of?",
        "What challenged you today, and how did you handle it?",
        "What are you grateful for from today?",
        "What did you learn about yourself today?",
        "What would you do differently if you could redo today?",
        "Who made a positive impact on your day?",
        "What moment brought you the most joy?",
        "What's one thing you want to let go of before tomorrow?",
        "How did you take care of yourself today?",
        "What surprised you today?",
        "What's still on your mind as the day ends?",
        "What progress did you make toward your goals?",
        "What conversation or interaction stood out today?",
        "How are you feeling right now, and why?"
    ]
}
