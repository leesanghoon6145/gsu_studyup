// cheer_phrases.dart
//
// 🆕 [부모 운동 응원별 2026-09-29] 별을 보낼 때 고르는 응원 문구 6개 (원장님 작성).
// 부모가 고른 언어(일반 플래너 언어 선택)에 맞는 문구가 보이고, 고른 문구가
// 그대로 자녀에게 전달된다. 없는 언어는 영어로, 영어도 없으면 한국어로 대체.

const Map<String, List<String>> kCheerPhrases = {
  'KO': [
    '너는 공부로 노력하고, 엄마 아빠는 운동으로 노력할게. 우리 가족 모두 함께 더 건강하고 성장하자!',
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

// 🆕 [응원 가족 2026-10-01] 할아버지·할머니·삼촌·고모·형·누나 등 "응원 가족"이 보낼 때만 보이는 문구 5개 (원장님 작성).
// 보호자(부모)가 보낼 때는 위의 부모 문구만, 응원 가족이 보낼 때는 이 문구만 보여서 서로 섞이지 않음.
const Map<String, List<String>> kFamilyCheerPhrases = {
  'KO': [
    '네가 꿈을 향해 한 걸음씩 나아가는 모습이 참 자랑스럽구나. 이 별에 응원을 담아 보낸다. 화이팅! ~^^',
    '나의 작은 노력으로 모은 별을 너에게 보낸다. 오늘도 너의 꿈을 향해 힘차게 나아가자. 힘내자 화이팅! ~^^',
    '공부하는 너의 시간 하나하나가 소중한 성장이란다. 사랑과 응원을 담아 별을 보낸다.',
    '네가 노력하는 만큼 꿈도 조금씩 가까워지고 있단다. 언제나 너의 도전을 응원할게. 화이팅! ~',
    '우리가 함께 모은 별이 너에게 힘이 되길 바란다. 포기하지 말고 너의 꿈을 향해 힘차게 나아가자. 화이팅!~^^',
  ],
  'EN': [
    'I\'m so proud to see you moving toward your dream one step at a time. I\'m sending my cheers in this star. You\'ve got this! ~^^',
    'I\'m sending you the stars I earned with my own small efforts. Keep moving boldly toward your dream today. Hang in there! ~^^',
    'Every moment you spend studying is precious growth. I\'m sending these stars with love and support.',
    'The harder you try, the closer your dream gets, little by little. I\'ll always cheer on your challenges. You can do it! ~',
    'I hope the stars we gathered together give you strength. Don\'t give up — keep moving boldly toward your dream. You\'ve got this! ~^^',
  ],
  'JA': [
    '夢に向かって一歩ずつ進むあなたの姿がとても誇らしいよ。この星に応援を込めて送るね。ファイト！~^^',
    '私の小さな努力で集めた星をあなたに送るよ。今日も夢に向かって力強く進もう。頑張れ！~^^',
    '勉強するあなたの時間ひとつひとつが大切な成長なんだよ。愛と応援を込めて星を送るね。',
    'あなたが努力するほど、夢も少しずつ近づいているよ。いつでもあなたの挑戦を応援しているよ。ファイト！~',
    'みんなで集めた星があなたの力になりますように。あきらめずに夢に向かって力強く進もう。ファイト！~^^',
  ],
  'ZH': [
    '看到你一步一步朝着梦想前进，真为你骄傲。把加油的心意装进这颗星星送给你。加油！~^^',
    '把我用小小努力攒下的星星送给你。今天也朝着梦想勇敢前进吧。加油！~^^',
    '你学习的每一刻都是珍贵的成长。带着爱和鼓励，把星星送给你。',
    '你越努力，梦想就离你越近。我会一直为你的挑战加油。加油！~',
    '希望我们一起攒下的星星能给你力量。不要放弃，朝着梦想勇敢前进吧。加油！~^^',
  ],
  'FR': [
    'Je suis si fier de te voir avancer vers ton rêve, un pas après l\'autre. Je t\'envoie mes encouragements dans cette étoile. Courage ! ~^^',
    'Je t\'envoie les étoiles gagnées grâce à mes petits efforts. Avance aujourd\'hui encore avec force vers ton rêve. Courage ! ~^^',
    'Chaque moment que tu passes à étudier est une belle croissance. Je t\'envoie ces étoiles avec amour et soutien.',
    'Plus tu fais d\'efforts, plus ton rêve se rapproche, petit à petit. J\'encouragerai toujours tes défis. Tu peux le faire ! ~',
    'J\'espère que les étoiles que nous avons réunies ensemble te donneront de la force. N\'abandonne pas et avance vers ton rêve. Courage ! ~^^',
  ],
  'DE': [
    'Ich bin so stolz zu sehen, wie du Schritt für Schritt deinem Traum entgegengehst. Mit diesem Stern schicke ich dir meine Anfeuerung. Du schaffst das! ~^^',
    'Ich schicke dir die Sterne, die ich mit meinen kleinen Mühen gesammelt habe. Geh auch heute mutig deinem Traum entgegen. Halte durch! ~^^',
    'Jede Minute, die du lernst, ist wertvolles Wachstum. Ich schicke dir diese Sterne mit Liebe und Unterstützung.',
    'Je mehr du dich anstrengst, desto näher kommt dein Traum, Stück für Stück. Ich feuere dich immer an. Du schaffst das! ~',
    'Ich hoffe, die Sterne, die wir gemeinsam gesammelt haben, geben dir Kraft. Gib nicht auf und geh mutig deinem Traum entgegen. Du schaffst das! ~^^',
  ],
  'RU': [
    'Я так горжусь тем, как ты шаг за шагом идёшь к своей мечте. Посылаю тебе свою поддержку в этой звезде. Удачи! ~^^',
    'Посылаю тебе звёзды, которые собрал своими небольшими усилиями. И сегодня смело иди к своей мечте. Держись! ~^^',
    'Каждая минута твоей учёбы — это ценный рост. Посылаю тебе эти звёзды с любовью и поддержкой.',
    'Чем больше ты стараешься, тем ближе становится мечта. Я всегда поддерживаю твои старания. У тебя всё получится! ~',
    'Пусть звёзды, которые мы собрали вместе, придадут тебе сил. Не сдавайся и смело иди к своей мечте. Удачи! ~^^',
  ],
  'AR': [
    'أنا فخور جدًا وأنا أراك تتقدم نحو حلمك خطوة بخطوة. أرسل لك تشجيعي في هذه النجمة. بالتوفيق! ~^^',
    'أرسل لك النجوم التي جمعتها بجهودي الصغيرة. تقدّم اليوم أيضًا بقوة نحو حلمك. لا تستسلم! ~^^',
    'كل لحظة تقضيها في الدراسة هي نمو ثمين. أرسل لك هذه النجوم بكل حب ودعم.',
    'كلما اجتهدت أكثر اقترب حلمك شيئًا فشيئًا. سأشجع تحدياتك دائمًا. تستطيع ذلك! ~',
    'أتمنى أن تمنحك النجوم التي جمعناها معًا القوة. لا تستسلم وتقدّم بقوة نحو حلمك. بالتوفيق! ~^^',
  ],
  'HI': [
    'तुम्हें अपने सपने की ओर कदम-दर-कदम बढ़ते देखकर मुझे बहुत गर्व है। इस सितारे में अपना प्रोत्साहन भेज रहा हूँ। शाबाश! ~^^',
    'अपनी छोटी-सी मेहनत से कमाए सितारे तुम्हें भेज रहा हूँ। आज भी अपने सपने की ओर हिम्मत से बढ़ो। हिम्मत रखो! ~^^',
    'पढ़ाई में बिताया तुम्हारा हर पल कीमती विकास है। प्यार और प्रोत्साहन के साथ ये सितारे भेज रहा हूँ।',
    'तुम जितनी मेहनत करोगे, सपना उतना ही पास आएगा। मैं हमेशा तुम्हारी कोशिशों के साथ हूँ। तुम कर सकते हो! ~',
    'आशा है कि हमारे साथ मिलकर जुटाए सितारे तुम्हें ताकत देंगे। हार मत मानो और अपने सपने की ओर बढ़ते रहो। शाबाश! ~^^',
  ],
  'VI': [
    'Thấy con từng bước tiến về phía ước mơ, ông bà/cô chú rất tự hào. Gửi lời cổ vũ trong ngôi sao này. Cố lên! ~^^',
    'Gửi con những ngôi sao được tích lũy từ những nỗ lực nhỏ bé. Hôm nay cũng hãy mạnh mẽ tiến về ước mơ nhé. Cố lên! ~^^',
    'Mỗi khoảnh khắc con học tập đều là sự trưởng thành quý giá. Gửi con những ngôi sao cùng yêu thương và cổ vũ.',
    'Con càng cố gắng, ước mơ càng đến gần hơn từng chút một. Luôn cổ vũ cho những thử thách của con. Cố lên! ~',
    'Mong những ngôi sao cả nhà cùng góp sẽ tiếp thêm sức mạnh cho con. Đừng bỏ cuộc, hãy mạnh mẽ tiến về ước mơ. Cố lên! ~^^',
  ],
  'ES': [
    'Estoy muy orgulloso de verte avanzar paso a paso hacia tu sueño. Te envío mi ánimo en esta estrella. ¡Tú puedes! ~^^',
    'Te envío las estrellas que gané con mis pequeños esfuerzos. Hoy también avanza con fuerza hacia tu sueño. ¡Ánimo! ~^^',
    'Cada momento que dedicas a estudiar es un crecimiento valioso. Te envío estas estrellas con amor y apoyo.',
    'Cuanto más te esfuerzas, más cerca está tu sueño, poco a poco. Siempre apoyaré tus desafíos. ¡Tú puedes! ~',
    'Espero que las estrellas que reunimos juntos te den fuerza. No te rindas y avanza con fuerza hacia tu sueño. ¡Ánimo! ~^^',
  ],
  'TH': [
    'ภูมิใจมากที่เห็นหลานก้าวไปหาความฝันทีละก้าว ขอส่งกำลังใจมาในดาวดวงนี้ สู้ ๆ นะ! ~^^',
    'ขอส่งดาวที่สะสมด้วยความพยายามเล็ก ๆ ของเราให้หลาน วันนี้ก็ก้าวไปหาความฝันอย่างเต็มที่นะ สู้ ๆ! ~^^',
    'ทุกช่วงเวลาที่หลานตั้งใจเรียนคือการเติบโตที่มีค่า ขอส่งดาวพร้อมความรักและกำลังใจ',
    'ยิ่งหลานพยายาม ความฝันก็ยิ่งใกล้เข้ามาทีละนิด จะคอยเป็นกำลังใจให้เสมอ สู้ ๆ นะ! ~',
    'หวังว่าดาวที่เราช่วยกันสะสมจะเป็นพลังให้หลาน อย่ายอมแพ้ ก้าวไปหาความฝันอย่างเต็มที่นะ สู้ ๆ! ~^^',
  ],
};

/// 응원 가족용 문구 5개 (없으면 영어 → 한국어 순서로 대체)
List<String> familyCheerPhrasesFor(String languageCode) {
  return kFamilyCheerPhrases[languageCode.toUpperCase()] ?? kFamilyCheerPhrases['EN'] ?? kFamilyCheerPhrases['KO']!;
}
