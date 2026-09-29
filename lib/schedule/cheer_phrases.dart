// cheer_phrases.dart
//
// 🆕 [부모 운동 응원별 2026-09-29] 별을 보낼 때 고르는 응원 문구 6개 (원장님 작성).
// 부모가 고른 언어(일반 플래너 언어 선택)에 맞는 문구가 보이고, 고른 문구가
// 그대로 자녀에게 전달된다. 없는 언어는 영어로, 영어도 없으면 한국어로 대체.

const Map<String, List<String>> kCheerPhrases = {
  'KO': [
    '너는 공부로 노력하고, 엄마 아빠는 운동으로 노력할게. 우리 가족 모두 함께 더 건강하게 성장하자!',
    '엄마 아빠도 건강을 위해 열심히 운동했어. 이 별에 담긴 마음처럼 너도 오늘 힘내서 공부하자!',
    '오늘도 열심히 운동해서 모은 별이야. 작은 별 하나하나에 너를 응원하는 엄마, 아빠의 마음을 담았단다.',
    '오늘 엄마 아빠가 운동하며 모은 별이야. 너에게 보내는 사랑과 응원의 마음이란다.',
    '엄마 아빠도 오늘의 건강을 위해 노력했어. 너도 네 꿈을 향해 힘차게 나아가자!',
    '부모님은 운동으로 건강을, 너는 공부로 꿈을 키우자. 우리 함께 힘내자!',
  ],
  'EN': [
    "You work hard at studying, and Mom and Dad will work hard at exercising. Let's all grow healthier and stronger together as a family!",
    "Mom and Dad worked out hard for our health, too. With the love in these stars, give your studies your best today!",
    "These are stars we earned by exercising hard today. Every little star holds Mom and Dad's heart cheering for you.",
    "Mom and Dad earned these stars by exercising today. They carry all our love and support for you.",
    "Mom and Dad worked hard for our health today, too. Now move boldly toward your dreams!",
    "Mom and Dad build health through exercise, and you build your dreams through study. Let's keep going together!",
  ],
  'JA': [
    'あなたは勉強で、ママとパパは運動で頑張るね。家族みんなで一緒に、もっと健康に成長しよう！',
    'ママとパパも健康のために一生懸命運動したよ。この星に込めた気持ちのように、今日も勉強がんばろうね！',
    '今日も一生懸命運動して集めた星だよ。小さな星ひとつひとつに、あなたを応援するママとパパの気持ちを込めたよ。',
    '今日ママとパパが運動して集めた星だよ。あなたへの愛と応援の気持ちだよ。',
    'ママとパパも今日の健康のために頑張ったよ。あなたも夢に向かって力強く進もう！',
    'パパとママは運動で健康を、あなたは勉強で夢を育てよう。一緒に頑張ろう！',
  ],
  'ZH': [
    '你用学习努力，爸爸妈妈用运动努力。我们全家一起更健康、一起成长吧！',
    '爸爸妈妈也为了健康努力运动了。就像这些星星里的心意一样，你今天也加油学习吧！',
    '这是今天努力运动攒下的星星。每一颗小星星里，都装着爸爸妈妈为你加油的心意。',
    '这是爸爸妈妈今天运动攒下的星星，是送给你的爱和鼓励。',
    '爸爸妈妈今天也为了健康努力了。你也朝着梦想勇敢前进吧！',
    '爸爸妈妈用运动收获健康，你用学习培育梦想。我们一起加油吧！',
  ],
  'FR': [
    "Toi, tu fais des efforts dans tes études, et Papa et Maman en font avec le sport. Grandissons ensemble, en meilleure santé, toute la famille !",
    "Papa et Maman ont aussi fait du sport avec ardeur pour leur santé. Avec tout l'amour de ces étoiles, donne le meilleur de toi dans tes études aujourd'hui !",
    "Ce sont des étoiles gagnées en faisant du sport avec ardeur aujourd'hui. Chaque petite étoile porte le soutien de Papa et Maman.",
    "Papa et Maman ont gagné ces étoiles en faisant du sport aujourd'hui. Elles portent tout notre amour et notre soutien.",
    "Papa et Maman ont aussi fait des efforts pour leur santé aujourd'hui. Toi aussi, avance avec force vers tes rêves !",
    "Papa et Maman cultivent leur santé par le sport, toi tes rêves par les études. Courage, ensemble !",
  ],
  'DE': [
    'Du strengst dich beim Lernen an, und Mama und Papa beim Sport. Lass uns als Familie gemeinsam gesünder werden und wachsen!',
    'Mama und Papa haben auch fleißig für ihre Gesundheit trainiert. Mit der Liebe in diesen Sternen – gib heute beim Lernen dein Bestes!',
    'Diese Sterne haben wir heute durch fleißiges Training gesammelt. In jedem kleinen Stern steckt Mamas und Papas Anfeuerung für dich.',
    'Diese Sterne haben Mama und Papa heute beim Sport gesammelt. Sie tragen unsere ganze Liebe und Unterstützung für dich.',
    'Mama und Papa haben sich heute auch für ihre Gesundheit angestrengt. Geh du auch kraftvoll deinen Träumen entgegen!',
    'Mama und Papa stärken ihre Gesundheit mit Sport, du deine Träume mit Lernen. Lass uns zusammen durchhalten!',
  ],
  'RU': [
    'Ты стараешься в учёбе, а мама и папа — в спорте. Давай всей семьёй становиться здоровее и расти вместе!',
    'Мама и папа тоже усердно занимались спортом ради здоровья. Пусть тепло этих звёзд придаст тебе сил в учёбе сегодня!',
    'Эти звёзды мы собрали сегодня, усердно занимаясь спортом. В каждой маленькой звёздочке — мамина и папина поддержка для тебя.',
    'Эти звёзды мама и папа собрали сегодня на тренировке. В них вся наша любовь и поддержка для тебя.',
    'Мама и папа сегодня тоже потрудились ради здоровья. И ты смело иди к своей мечте!',
    'Мама и папа укрепляют здоровье спортом, а ты растишь мечту учёбой. Вместе у нас всё получится!',
  ],
  'AR': [
    'أنت تجتهد في دراستك، وأمي وأبي سيجتهدان في الرياضة. لننمُ معًا كعائلة بصحة أفضل!',
    'أمي وأبي أيضًا تمرّنا بجد من أجل صحتهما. وبروح هذه النجوم، اجتهد في دراستك اليوم!',
    'هذه نجوم جمعناها اليوم بالتمرين بجد. في كل نجمة صغيرة قلبُ أمي وأبي الذي يشجعك.',
    'هذه نجوم جمعها أمي وأبي اليوم أثناء التمرين، وهي تحمل لك حبنا وتشجيعنا.',
    'أمي وأبي بذلا جهدهما اليوم من أجل صحتهما. وأنت أيضًا، تقدّم بقوة نحو أحلامك!',
    'نحن نبني صحتنا بالرياضة، وأنت تبني أحلامك بالدراسة. هيا نجتهد معًا!',
  ],
  'HI': [
    'तुम पढ़ाई में मेहनत करो, मम्मी-पापा व्यायाम में मेहनत करेंगे। आओ, पूरा परिवार मिलकर और स्वस्थ बने और आगे बढ़े!',
    'मम्मी-पापा ने भी सेहत के लिए खूब व्यायाम किया। इन सितारों में छिपे प्यार की तरह, तुम भी आज मन लगाकर पढ़ाई करो!',
    'ये सितारे आज मेहनत से व्यायाम करके जुटाए हैं। हर छोटे सितारे में तुम्हारा हौसला बढ़ाता मम्मी-पापा का प्यार है।',
    'ये सितारे आज मम्मी-पापा ने व्यायाम करते हुए जुटाए हैं। इनमें तुम्हारे लिए हमारा प्यार और हौसला है।',
    'मम्मी-पापा ने भी आज सेहत के लिए मेहनत की। तुम भी अपने सपनों की ओर पूरे जोश से आगे बढ़ो!',
    'मम्मी-पापा व्यायाम से सेहत बनाएं, तुम पढ़ाई से सपने। आओ, मिलकर हिम्मत रखें!',
  ],
  'VI': [
    'Con cố gắng học tập, còn bố mẹ cố gắng tập thể dục. Cả nhà mình cùng khỏe mạnh và trưởng thành hơn nhé!',
    'Bố mẹ cũng đã chăm chỉ tập thể dục vì sức khỏe. Như tấm lòng gửi trong những ngôi sao này, hôm nay con cũng cố gắng học nhé!',
    'Đây là những ngôi sao bố mẹ chăm chỉ tập luyện hôm nay mới có được. Mỗi ngôi sao nhỏ đều chứa tấm lòng cổ vũ con của bố mẹ.',
    'Đây là những ngôi sao bố mẹ có được khi tập thể dục hôm nay, gửi đến con cả tình yêu và sự cổ vũ.',
    'Hôm nay bố mẹ cũng đã cố gắng vì sức khỏe. Con cũng hãy mạnh mẽ tiến về phía ước mơ nhé!',
    'Bố mẹ rèn sức khỏe bằng thể thao, con vun đắp ước mơ bằng học tập. Cùng nhau cố gắng nhé!',
  ],
  'ES': [
    'Tú te esfuerzas estudiando, y mamá y papá nos esforzaremos haciendo ejercicio. ¡Crezcamos juntos como familia, más sanos y más fuertes!',
    'Mamá y papá también hicimos ejercicio con ganas por nuestra salud. ¡Con el cariño de estas estrellas, esfuérzate hoy en tus estudios!',
    'Son estrellas que ganamos hoy haciendo ejercicio con esfuerzo. Cada pequeña estrella lleva el ánimo de mamá y papá para ti.',
    'Mamá y papá ganamos estas estrellas haciendo ejercicio hoy. Llevan todo nuestro amor y ánimo para ti.',
    'Mamá y papá también nos esforzamos hoy por nuestra salud. ¡Tú también avanza con fuerza hacia tus sueños!',
    'Mamá y papá cultivan su salud con ejercicio, y tú tus sueños con el estudio. ¡Ánimo, juntos!',
  ],
  'TH': [
    'ลูกตั้งใจเรียน ส่วนพ่อแม่จะตั้งใจออกกำลังกาย มาเติบโตและแข็งแรงไปด้วยกันทั้งครอบครัวนะ!',
    'พ่อแม่ก็ออกกำลังกายอย่างตั้งใจเพื่อสุขภาพเหมือนกัน เหมือนความรู้สึกที่อยู่ในดาวเหล่านี้ วันนี้ลูกก็ตั้งใจเรียนนะ!',
    'นี่คือดาวที่พ่อแม่สะสมจากการออกกำลังกายอย่างตั้งใจวันนี้ ดาวทุกดวงมีกำลังใจจากพ่อแม่ที่ส่งให้ลูก',
    'นี่คือดาวที่พ่อแม่สะสมจากการออกกำลังกายวันนี้ เป็นความรักและกำลังใจที่ส่งให้ลูก',
    'วันนี้พ่อแม่ก็พยายามเพื่อสุขภาพเหมือนกัน ลูกก็ก้าวไปสู่ความฝันอย่างเต็มกำลังนะ!',
    'พ่อแม่สร้างสุขภาพด้วยการออกกำลังกาย ลูกสร้างความฝันด้วยการเรียน มาสู้ไปด้วยกันนะ!',
  ],
};

/// 지금 언어에 맞는 응원 문구 6개 (없으면 영어 → 한국어 순서로 대체)
List<String> cheerPhrasesFor(String languageCode) {
  return kCheerPhrases[languageCode.toUpperCase()] ?? kCheerPhrases['EN'] ?? kCheerPhrases['KO']!;
}
