import Foundation

// MARK: - Модели запроса/ответа Yandex GPT
struct YandexGPTMessage: Codable {
    let role: String   // "system", "user", "assistant"
    let text: String
}

struct CompletionOptions: Codable {
    let stream: Bool
    let temperature: Double
    let maxTokens: Int
}

struct YandexGPTRequest: Codable {
    let modelUri: String
    let completionOptions: CompletionOptions
    let messages: [YandexGPTMessage]
}

struct YandexGPTResponse: Codable {
    let result: YandexGPTResult
}

struct YandexGPTResult: Codable {
    let alternatives: [YandexGPTAlternative]
}

struct YandexGPTAlternative: Codable {
    let message: YandexGPTMessage
}

// MARK: - Сервис
class AIService {
    private let apiKey: String
    private let folderId: String
    private let url = URL(string: "https://llm.api.cloud.yandex.net/foundationModels/v1/completion")!
    
    // Инициализатор с параметрами (позже можно будет брать из настроек)
    init(apiKey: String, folderId: String) {
        self.apiKey = apiKey
        self.folderId = folderId
    }
    
    // Удобный метод для получения мотивационного сообщения
    func generateMotivation(statistics: String, yesterdayLevel: DrinkLevel? = nil, completion: @escaping (String?) -> Void) {
        print("🚀 Отправляем запрос к Yandex GPT со статистикой: \(statistics), уровень вчера: \(yesterdayLevel?.rawValue ?? "nil")")
        
        let systemPrompt: String
        if let level = yesterdayLevel {
            // Вчера был алкоголь
            systemPrompt = """
            Ты — персональный тренер в приложении для людей, которые следят за потреблением алкоголя и спортом. Пользователь вчера выпил алкоголь. Твоя задача — простебать его, используя чёрный юмор.

            Вот примеры твоих сообщений:
            - "Твой кошелёк не резиновый. Баланс на дне, как и ты после вчерашнего."
            - "Твоя печень плачет. А ты нет, потому что обезвожен."
            - "Ты пропиваешь не только деньги, но и лицо. Скоро в паспорте будешь страшнее, чем в жизни."
            - "Твой уровень алкоголя в крови уже выше, чем твой IQ."
            - "Ты не пьёшь — это выпивка пьёт тебя. Возьми бразды правления обратно."
            - "Ты просадил все бабки и здоровье. Поздравляю, ты спонсор собственного похмелья."
            - "Твой мозг уже просит политического убежища в другой голове."
            - "Ты перешёл все границы. Даже границу «всрало». Добро пожаловать в запой!"
            - "Твой вчерашний девиз: «Пить до дна!». И ты допил. Даже дно пожаловалось на тебя."
            - "Ты вчера провёл социологическое исследование «Как люди живут без мозгов». Сегодня время для выводов."

            Твоё сообщение должно быть очень кратким (одно предложение, 30-40 слов), чёрный юмор. Обязательно упомяни факт вчерашнего алкоголя и его последствия. Не используй шаблоны из примеров дословно — адаптируй под ситуацию.
            """
        } else {
            // Вчера трезвый день
            systemPrompt = """
            Ты — персональный тренер в приложении для людей, которые следят за потреблением алкоголя и спортом. Пользователь вчера НЕ выпил алкоголь. Твоя задача — простебать его, используя чёрный юмор.

            Вот примеры твоих сообщений (адаптируй их под статистику пользователя):
            - "Ты не бухаешь, ты кайфуешь. Остальным на это сил не хватает."
            - "Твой утренний режим — проснуться, а не выжить. Победа."
            - "Ты не пил, а значит, завтра ты проснёшься с единственной болью — экзистенциальной."
            - "Пока все тусят в сортире, ты тусишь в жизни. Выигрыш очевиден."
            - "Ты не скучный, ты адекватный. Это новый чёрный, остальные просто не в теме."
            - "У тебя утром планы, а у них — приговор. Чувствуешь разницу?"
            - "Ты не травишь себя дрянью. Инстинкт самосохранения включился. Красава."
            - "Пока они сливают бабки в унитаз, ты копишь на что-то офигенное. Кто кого?"
            - "Твой календарь чист от позора. Выглядит подозрительно... Может, просто забыл отметить?"
            - "У тебя с утра ясная голова и полный кошелёк. Выглядишь подозрительно успешным."

            Сообщение должно быть одним предложением, с лёгкой иронией, использовать цифры из статистики (сколько трезвых дней, спорта и т.п.). Не копируй примеры дословно — придумай своё на их основе.
            """
        }
        
        // Формируем сообщение пользователя (теперь оно очень простое)
        let userPrompt: String
        if let level = yesterdayLevel {
            userPrompt = """
            Вот статистика пользователя за последние 7 дней: \(statistics).
            Вчера он выпил \(level.rawValue). Напиши короткое сообщение в стиле примеров выше.
            """
        } else {
            userPrompt = """
            Статистика пользователя за последние 7 дней: \(statistics). Вчера он не пил. Напиши короткое сообщение в стиле примеров.
            """
        }
        
        // Создаём тело запроса
        let messages = [
            YandexGPTMessage(role: "system", text: systemPrompt),
            YandexGPTMessage(role: "user", text: userPrompt)
        ]
        
        let options = CompletionOptions(stream: false, temperature: 0.7, maxTokens: 150)
        let requestBody = YandexGPTRequest(
            modelUri: "gpt://\(folderId)/yandexgpt-lite",
            completionOptions: options,
            messages: messages
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("❌ Ошибка кодирования запроса: \(error)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Ошибка сети: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ Нет данных в ответе")
                completion(nil)
                return
            }
            
            if let rawString = String(data: data, encoding: .utf8) {
                print("📄 Сырой ответ: \(rawString)")
            }
            
            do {
                let response = try JSONDecoder().decode(YandexGPTResponse.self, from: data)
                let answer = response.result.alternatives.first?.message.text
                print("✅ Получен ответ от AI: \(answer ?? "nil")")
                completion(answer)
            } catch {
                print("❌ Ошибка парсинга ответа: \(error)")
                completion(nil)
            }
        }.resume()
    }}
