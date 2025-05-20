extends Control

@onready var question_label = $MarginContainer/VBoxContainer/Question
@onready var answer_container = $MarginContainer/VBoxContainer/CenterContainer/AnswerContainer
@onready var score_label = $HBoxContainer/ScoreNumber
@onready var confirm_label = $MarginContainer/VBoxContainer/AnswerConfirm
@onready var media_container = $MarginContainer/VBoxContainer/MediaContainer
@onready var audio_streamer = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/PlayButton/Audio
@onready var question_image = $MarginContainer/VBoxContainer/MediaContainer/Photo
@onready var audio_timer = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/AudioTimer
@onready var audio_container = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer

@onready var answer_panel_path = $Answer/PanelContainer
@onready var next_question_button_path = $Answer/PanelContainer/VBoxContainer/NextQuestion
@onready var answer_text_path = $Answer/PanelContainer/VBoxContainer/TextEdit
@onready var answer_input = $MarginContainer/VBoxContainer/AnswerInput

var question_data = preload("res://all_questions.tres")
var regular_font = load("res://font/calibri-regular.ttf")
var selected_questions: Array = []
var current_question_index: int = 0
var score: int = 0
var current_question
var answer_group
var correct_answer
var buttons: Array = []
var showing_answer = false
var paused_position = 0.0

enum InputAnswerMatch {
    WRONG,
    ADEQUATE,
    CORRECT
}

func _ready() -> void:
    # Initialize the ButtonGroup
    answer_group = ButtonGroup.new()
    next_question_button_path.pressed.connect(_next_question)

    # Initialize buttons array
    buttons = [
        answer_container.get_node("Answer1"),
        answer_container.get_node("Answer2"),
        answer_container.get_node("Answer3"),
        answer_container.get_node("Answer4")
    ]

    # Assign buttons to the ButtonGroup
    for button in buttons:
        button.set_button_group(answer_group)
    # Start the game
    choose_questions()
    current_question_handling()

#func _process(delta: float) -> void:
    #if audio_streamer.playing and audio_streamer.stream != null:
        #audio_timer.value = audio_streamer.get_playback_position()

func choose_questions() -> void: 
    var all_questions = question_data.questions#.filter(func(q):
        #return q.question_type == q.QuestionType.MULTIPLE_CHOICE)#&& q.media_path) #--- uncomment for just questions including media
    all_questions.shuffle()
    selected_questions = all_questions.slice(0, 10)  # Select the first 10 elements

# manages if game ended, switches question to next, shows/hides apropriate nodes
func current_question_handling() -> void: 
    if current_question_index < selected_questions.size():  # == Still questions left
        current_question = selected_questions[current_question_index] #set next question in line to current
        
        if current_question.question_type == current_question.QuestionType.MULTIPLE_CHOICE: #question is multiple choice
            multiple_choice_shuffle()
            answer_input.set_visible(false)
            
        else: #question is input answer
            answer_input.set_visible(true)

        assign_answers_to_buttons(current_question.answers) #this will hide the buttons for answer input types, since it has .answers is null
        media_visibility_management(current_question.media_path.get_extension())
        question_label.text = current_question.question_text

    else:  # No questions left
        show_score()

func multiple_choice_shuffle() -> void:
    var correct_text = current_question.answers[current_question.correct_answer_index]
    current_question.answers.shuffle()
    current_question.correct_answer_index = current_question.answers.find(correct_text)
    correct_answer = "Answer" + str(current_question.correct_answer_index + 1)
    print("The correct answer is: ", correct_answer)

func media_visibility_management(file_extension: String) -> void:
    if current_question.media_path != "":
        media_container.set_visible(true)
        match file_extension:
        
            "png", "jpg", "jpeg": 
                question_image.set_visible(true)
                audio_container.set_visible(false)

            # Add error handling for image loading
                var image = ResourceLoader.load(current_question.media_path)
                if image:
                    question_image.texture = image
                else:
                    push_error("Failed to load image: " + current_question.media_path)

            "mp3", "wav": 
                question_image.set_visible(false)
                audio_container.set_visible(true)

                # Add error handling for audio loading
                var audio_resource = ResourceLoader.load(current_question.media_path)
                if audio_resource:
                    audio_streamer.stream = audio_resource
                    var audio_length = audio_streamer.stream.get_length()
                    audio_timer.max_value = audio_length
                    # Reset audio state
                    paused_position = 0.0
                else:
                    push_error("Failed to load audio: " + current_question.media_path)
    else:
        $MarginContainer/VBoxContainer/MediaContainer/NoMediaPicture.set_visible(true)
        question_image.set_visible(false)
        audio_container.set_visible(false)

func assign_answers_to_buttons(answers: Array[String]) -> void:
    # First hide all buttons
    for button in buttons:
        button.visible = false

    # Show only the buttons we need
    for i in range(min(answers.size(), buttons.size())):
        buttons[i].text = answers[i]
        buttons[i].visible = true

func show_new_question() -> void:
    showing_answer = false
    current_question_index += 1
    for button in buttons:
        button.add_theme_stylebox_override("disabled",  load("res://disabled_neutral.tres"))
        button.disabled = false

    question_label.add_theme_font_override("font", regular_font)
    confirm_label.text = "Potvrdit odpověď!"
    current_question_handling()
    unpress_all_buttons()

func unpress_all_buttons() -> void:
    for button in buttons:
        button.set_pressed(false)

func show_answer(pressed_button: Button) -> void:
    for button in buttons:
        button.disabled = true

    if pressed_button.name == correct_answer:
        pressed_button.add_theme_stylebox_override("disabled",  load("res://correct_answer.tres"))
        score += 1
        score_label.text = str(score)

    else:
        pressed_button.add_theme_stylebox_override("disabled",  load("res://wrong_answer.tres"))
        var correct_button =  str("MarginContainer/VBoxContainer/CenterContainer/AnswerContainer/%s" % correct_answer)
        get_node(correct_button).add_theme_stylebox_override("disabled",  load("res://correct_answer.tres"))

    showing_answer = true
        # Reset audio state
    if audio_streamer.playing:
        audio_streamer.stop()
        paused_position = 0.0
        
    if current_question.answer_info: 
        answer_text_path.text = current_question.answer_info
        $Answer.set_visible(true)
        await get_tree().create_timer(1).timeout 
        answer_panel_path.set_visible(true)

    else:
        await get_tree().create_timer(1).timeout 
        show_new_question()

    print("Showing answer? ",showing_answer)

func _next_question() -> void:
    show_new_question()
    $Answer.set_visible(false)
    answer_panel_path.set_visible(false)

func _on_answer_confirm_pressed() -> void: 
    if showing_answer == true: 
        show_new_question()
    else:
        if current_question.question_type == current_question.QuestionType.MULTIPLE_CHOICE:
            if answer_group.get_pressed_button() : # Only advance if an answer was selected
                show_answer(answer_group.get_pressed_button())
            else:
                print("No button selected!")
            # Maybe show a message to the player that they need to select an answer
        else: #question is input answer
            var actual_answer = answer_input.text
            print(current_question.correct_answer_text)
            check_input_answer(current_question.correct_answer_text, actual_answer)

func check_input_answer(expected_answer: String, actual_answer: String) -> InputAnswerMatch:
    var ts = TextServerManager.get_primary_interface()
    actual_answer = ts.strip_diacritics(actual_answer).to_lower()
    expected_answer = ts.strip_diacritics(expected_answer).to_lower()

    var distance = edit_distance(expected_answer, actual_answer)
    var max_distance = max(2, int(expected_answer.length() / 3))

    if expected_answer == actual_answer:
        print("The input answer is fully correct")
        return InputAnswerMatch.CORRECT
    elif distance <= max_distance:
        print("The input answer is almost correct")
        return InputAnswerMatch.ADEQUATE
    else:
        print("The input answer is wrong")
        return InputAnswerMatch.WRONG

func edit_distance(s1: String, s2: String) -> int:
    var len1 = s1.length()
    var len2 = s2.length()

    # Create a 2D array (len1+1 x len2+1) initialized with zeros
    var dp := []
    for i in range(len1 + 1):
        dp.append([])
        for j in range(len2 + 1):
            dp[i].append(0)
    
    # Initialize base cases
    for i in range(len1 + 1):
        dp[i][0] = i
    for j in range(len2 + 1):
        dp[0][j] = j
    
    # Fill the matrix
    for i in range(1, len1 + 1):
        for j in range(1, len2 + 1):
            var cost = 0 if s1[i - 1] == s2[j - 1] else 1
            dp[i][j] = min(
                dp[i - 1][j] + 1,      # Deletion
                dp[i][j - 1] + 1,      # Insertion
                dp[i - 1][j - 1] + cost  # Substitution
            )
    return dp[len1][len2]

func _on_play_button_pressed() -> void: 
    if audio_streamer.playing:
        # Pause audio and save position
        paused_position = audio_streamer.get_playback_position()
        audio_streamer.stream_paused = true
        print("Pausing audio at position: ", paused_position)
    else:
# If it's not playing at all (first play), start it
        if !audio_streamer.playing and paused_position == 0.0:
            print("Starting audio from beginning")
            audio_streamer.play()
        else:
            # Resume from saved position
            print("Resuming audio from position: ", paused_position)
            audio_streamer.stream_paused = false

func reset_game() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func show_score() -> void:
    media_container.set_visible(false)
    question_label.text = "Konec hry! Tvoje skóre: " + str(score)
    for button in buttons:
        button.visible = false
# Show a restart button
    confirm_label.text = "Hrát znovu"
    confirm_label.pressed.connect(reset_game)
