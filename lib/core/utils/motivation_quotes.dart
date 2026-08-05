/// 홈 화면에 보여 줄 동기부여 명언 모음(영어 원문 + 한글 뜻).
/// 30분마다 다음 명언으로 바뀐다. 시계만 보고 고르므로 어느 기기에서든
/// 같은 시간대에는 같은 명언이 보이고, 저장할 상태가 없다.
class Quote {
  const Quote(this.english, this.korean, this.author);

  final String english;
  final String korean;
  final String author;
}

/// 30분마다 바뀌는 명언. [at]을 주면 그 시각 기준으로 고른다(테스트용).
Quote currentQuote([DateTime? at]) {
  final now = at ?? DateTime.now();
  final halfHours = now.millisecondsSinceEpoch ~/ (30 * 60 * 1000);
  return kQuotes[halfHours % kQuotes.length];
}

/// 다음 명언으로 바뀌기까지 남은 시간.
Duration untilNextQuote([DateTime? at]) {
  final now = at ?? DateTime.now();
  const slot = 30 * 60 * 1000;
  final passed = now.millisecondsSinceEpoch % slot;
  return Duration(milliseconds: slot - passed);
}

const List<Quote> kQuotes = [
  Quote('The secret of getting ahead is getting started.', '앞서가는 비결은 일단 시작하는 것이다.',
      'Mark Twain'),
  Quote('It always seems impossible until it is done.', '해내기 전까지는 늘 불가능해 보인다.',
      'Nelson Mandela'),
  Quote('Success is the sum of small efforts repeated day in and day out.',
      '성공은 매일 반복한 작은 노력들의 합이다.', 'Robert Collier'),
  Quote('Believe you can and you are halfway there.',
      '할 수 있다고 믿으면 이미 절반은 온 것이다.', 'Theodore Roosevelt'),
  Quote('The expert in anything was once a beginner.',
      '어떤 분야의 전문가도 한때는 초보였다.', 'Helen Hayes'),
  Quote('Do not watch the clock. Do what it does. Keep going.',
      '시계를 보지 말고 시계처럼 하라. 계속 나아가라.', 'Sam Levenson'),
  Quote('Little by little, one travels far.', '조금씩 가다 보면 멀리 간다.',
      'J. R. R. Tolkien'),
  Quote('Quality is not an act, it is a habit.', '탁월함은 행동이 아니라 습관이다.',
      'Aristotle'),
  Quote('The best way to predict the future is to create it.',
      '미래를 예측하는 가장 좋은 방법은 미래를 만드는 것이다.', 'Peter Drucker'),
  Quote('Fall seven times, stand up eight.', '일곱 번 넘어지면 여덟 번 일어나라.',
      'Japanese Proverb'),
  Quote('A year from now you may wish you had started today.',
      '1년 뒤엔 오늘 시작했더라면 하고 바랄지도 모른다.', 'Karen Lamb'),
  Quote('Learning never exhausts the mind.', '배움은 결코 마음을 지치게 하지 않는다.',
      'Leonardo da Vinci'),
  Quote('Discipline is choosing between what you want now and what you want most.',
      '절제란 지금 원하는 것과 가장 원하는 것 사이의 선택이다.', 'Abraham Lincoln'),
  Quote('The only way to do great work is to love what you do.',
      '위대한 일을 하는 유일한 방법은 자기 일을 사랑하는 것이다.', 'Steve Jobs'),
  Quote('Start where you are. Use what you have. Do what you can.',
      '지금 있는 자리에서, 가진 것으로, 할 수 있는 것을 하라.', 'Arthur Ashe'),
  Quote('Perseverance is not a long race; it is many short races one after another.',
      '끈기란 긴 경주가 아니라 짧은 경주를 연달아 하는 것이다.', 'Walter Elliot'),
  Quote('Whether you think you can or you think you cannot, you are right.',
      '할 수 있다고 생각하든 없다고 생각하든, 당신 생각이 맞다.', 'Henry Ford'),
  Quote('Knowledge is power.', '아는 것이 힘이다.', 'Francis Bacon'),
  Quote('Practice makes progress, not perfection.',
      '연습은 완벽이 아니라 성장을 만든다.', 'Unknown'),
  Quote('There is no substitute for hard work.', '노력을 대신할 수 있는 것은 없다.',
      'Thomas Edison'),
  Quote('The future depends on what you do today.',
      '미래는 오늘 무엇을 하느냐에 달려 있다.', 'Mahatma Gandhi'),
  Quote('Great things are done by a series of small things brought together.',
      '위대한 일은 작은 일들이 모여 이루어진다.', 'Vincent van Gogh'),
  Quote('You do not have to be great to start, but you have to start to be great.',
      '시작하려고 위대할 필요는 없지만, 위대해지려면 시작해야 한다.', 'Zig Ziglar'),
  Quote('Energy and persistence conquer all things.', '열정과 끈기는 모든 것을 이긴다.',
      'Benjamin Franklin'),
  Quote('Doubt kills more dreams than failure ever will.',
      '실패보다 의심이 더 많은 꿈을 죽인다.', 'Suzy Kassem'),
  Quote('Study without desire spoils the memory.',
      '하고 싶은 마음 없이 하는 공부는 기억을 망친다.', 'Leonardo da Vinci'),
  Quote('Every accomplishment starts with the decision to try.',
      '모든 성취는 해보겠다는 결심에서 시작된다.', 'John F. Kennedy'),
  Quote('The mind is not a vessel to be filled but a fire to be kindled.',
      '마음은 채워야 할 그릇이 아니라 지펴야 할 불이다.', 'Plutarch'),
  Quote('Hard work beats talent when talent does not work hard.',
      '재능이 노력하지 않으면 노력이 재능을 이긴다.', 'Tim Notke'),
  Quote('Do what you can, with what you have, where you are.',
      '있는 자리에서 가진 것으로 할 수 있는 것을 하라.', 'Theodore Roosevelt'),
  Quote('Mistakes are proof that you are trying.', '실수는 당신이 시도하고 있다는 증거다.',
      'Jennifer Lim'),
  Quote('An investment in knowledge pays the best interest.',
      '지식에 대한 투자가 가장 좋은 이자를 준다.', 'Benjamin Franklin'),
  Quote('The journey of a thousand miles begins with one step.',
      '천 리 길도 한 걸음부터.', 'Lao Tzu'),
  Quote('Be so good they cannot ignore you.', '무시할 수 없을 만큼 잘해라.',
      'Steve Martin'),
  Quote('What we learn with pleasure we never forget.',
      '즐겁게 배운 것은 결코 잊지 않는다.', 'Alfred Mercier'),
  Quote('Success is not final, failure is not fatal.',
      '성공이 끝은 아니고, 실패가 치명적인 것도 아니다.', 'Winston Churchill'),
  Quote('You miss one hundred percent of the shots you do not take.',
      '시도하지 않은 슛은 100퍼센트 빗나간다.', 'Wayne Gretzky'),
  Quote('Motivation gets you started. Habit keeps you going.',
      '동기는 시작하게 하고, 습관은 계속하게 한다.', 'Jim Ryun'),
  Quote('If you are working on something exciting, it will keep you motivated.',
      '설레는 일을 하고 있다면 그것이 당신을 계속 움직이게 한다.', 'Steve Jobs'),
  Quote('Genius is one percent inspiration and ninety-nine percent perspiration.',
      '천재는 1퍼센트의 영감과 99퍼센트의 노력이다.', 'Thomas Edison'),
  Quote('Try not to become a person of success, but a person of value.',
      '성공한 사람이 아니라 가치 있는 사람이 되려고 하라.', 'Albert Einstein'),
  Quote('Push yourself, because no one else is going to do it for you.',
      '스스로를 밀어붙여라. 누구도 대신해 주지 않는다.', 'Unknown'),
  Quote('Dreams do not work unless you do.', '당신이 움직이지 않으면 꿈도 움직이지 않는다.',
      'John C. Maxwell'),
  Quote('The harder you work for something, the greater you will feel when you achieve it.',
      '더 열심히 얻은 것일수록 이뤘을 때 더 크게 느껴진다.', 'Unknown'),
  Quote('Change your thoughts and you change your world.',
      '생각을 바꾸면 세상이 바뀐다.', 'Norman Vincent Peale'),
  Quote('It is not that I am so smart, I just stay with problems longer.',
      '내가 똑똑한 게 아니라, 문제를 더 오래 붙들고 있을 뿐이다.', 'Albert Einstein'),
  Quote('Nothing will work unless you do.', '당신이 하지 않으면 아무것도 되지 않는다.',
      'Maya Angelou'),
  Quote('The beautiful thing about learning is that no one can take it away from you.',
      '배움의 아름다운 점은 누구도 빼앗아 갈 수 없다는 것이다.', 'B. B. King'),
  Quote('Small steps every day add up to big results.',
      '매일의 작은 걸음이 모여 큰 결과가 된다.', 'Unknown'),
  Quote('Today is always the best day to begin.', '시작하기에 가장 좋은 날은 언제나 오늘이다.',
      'Unknown'),
];
