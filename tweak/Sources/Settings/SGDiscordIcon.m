#import "SGPageStyle.h"

UIImage *SGDiscordIcon(void) {
    static UIImage *icon;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *base64 =
            @"iVBORw0KGgoAAAANSUhEUgAAAE4AAAA8CAYAAADIQIzXAAAI5UlEQVR42u2cf4wdVRXHPzPvtWkL"
            @"pZZdW2obamkppVgtUIuKSq1IUQoalVRUIIoxGInR+K8/ozH+oYkxJoY0xqChatEoiNVYUROJJkpU"
            @"yJpK0UrRmiUUy3btD7pv5usfc245Hea9N/Nmdlm7vcnNezt77z33fu855557zpkXSaKBElvt5J6f"
            @"A1wCbLR6CXAH8CDQApKadMMYm4CvACPA763+BRjPtW8DqdVaJaoBXOQm7gdZawt5A7ABON9ADWU3"
            @"cI09kxvLf/rvfmzlPiMD4QFgs2uXAvuBh4BfAr8G/pobO7Z2mirgYiPsuWU98FbgeuDSHFC4trJd"
            @"f6MtJqrBdS0b7yoDp+PAbhXQ/yPwY+Be4JGCcdLJBC5yO7QEuBHYBrwqB1ZYRJR7nthEfwa82f43"
            @"H1gADNn3s4HZBnAY61ngv1YPAodNDFPgfuA6N7bnOhUAmQK/Bb4L/AAYdQyRTgZwYeDLgA8C7wCG"
            @"c2DFDrBepWMcNwwsNcDmlJzHMQPwgIF4FTCrTx85rmq7508B9wDbgT9XAa8scEGXvRv4tuOiJCe+"
            @"dYsXGa/HopIbUpVGy63jXcD3yx5aZYALIC2yU2sImLCdq7OQpACMqMSi81zUqglixzj2SWAd8LQT"
            @"6b6g9NNrKfAlAy0QihowJeKK3BTldGer5hwiW0sHWAx82dYa1eW4wLab7chPGpjsdC1hbZuBX/UT"
            @"2V7ARc5Wewh4+QwB7mEz1jtOHVQS1XDC3DYDQPPS9QrgA7b2uCrHBRlfYFeXJYZ8zOldgn4btRvQ"
            @"WMGh1JPjgjV9B/CSfuifRiVI2RLgY72YpYjjwh1yCNhjn5ohwHmuOwSsMSM7ypsncRfUBdxuln0y"
            @"g0DzXHcu8OFuTJPnuKDb5ps34bwZxm15Q/sp47pn8rou7qLb3mNyns5A0LzRv8iweN4NpYjjWuaC"
            @"WTeDgcOtfY+5zSY818UF3LbpDGin6LqL7TZxisoqAua2QRx7pzHXCXh/t8MhoLsY2EsWK1BDbpz/"
            @"90MiAo4AF5H5AGMgjXOcd72BlpwB7aTOT4CzgK0eqzjne7px0OBFSQ/sVHDIZM3/nR6rSFIQ06XA"
            @"o4ZuE2IqZ4X7DUrtIIoaXFTiQpRN0wlYHDOb7gkg9sQ2G2hNiGnqTJuwMWFx7aIrTE06bRs7cdZA"
            @"U3SCuM4Frg7i6mOb13bzBAxo/yTAXWRhwzWmXLcAXyWLUMU1A9KBznHgTuAtRuMi00fb7X9xA+AF"
            @"TLac/FsSkuZIelxZSTR4CX33SbrSxi6qayT9rga90OcRSZf2oHO5pJEG1/VPSfMkEQisl5RarTN4"
            @"Kunfki6wcWdJakmKrbbsGZIWSPrTAIsKdPZKWmxjtQvotO1/50l6zPrUAS/gs0HSSf22sUF9cDuw"
            @"jyyoPOH0TtBzE2QBkjHgZhOnqioiNaP0SRdsydMJQaVRa6sGXOuRYXUKcHX0W1D8DwL32aFwokf7"
            @"EF4cAb5TQd8FOvcbrba7Q/ai8xvgJw3oVYBX+kDyupJxzX7Kc0eFUF845ndUCFWGcnfFuUbWp+7d"
            @"FeBl4VQdBlYMMPm8OwrgDxXuueEeOEKW0hD34fjg2umY96YqnYetb2tAyQobtQIYjsOXGhznDcSD"
            @"A/Qf57noeZkFHbJatr1cv/Ga+hvzDK+MgQsbPBiiGkmJ041OL4N7VQysrHkwhNSvORU514cgq/Rb"
            @"aLtelU5II2vCEF4ZO/1W96iGLE+u7ILCwbTerjP9cjYiFxTfUJB714/O5e5UrXulXBHb5Z6ag4UF"
            @"vLci98psuaocf0vF9p4ODei5pbFj+ybczBuBm2xXZ/doH4zWK4C3O09GmdM7tTvjm2yMMnS2mBMj"
            @"bSiNYziStM/Eta4rKfjCDpHFLUbM+FRBkmAHeLEZsasrxjeCSB8AXkuWJN2LznKjs5T6oc6A0f6Y"
            @"LOeWBtl4CPi57XK3q9BlZKlUqwcICgV7bxlZ6tmVPei8xtosazg+fHYkabxB8MgB8UNgJ1kcIwFe"
            @"CryNLFY5q2YkLXUq4ntkidB/t/+tMhWwzbVpMmJ3NJI0kUsobjLI0etZ2pBdFfehOxlhzqQ9SUGZ"
            @"KGemtHLvNMQNLSbukQzdJJ3n0Y0kdaYgYVANmDzTik48RYHnaIrCjVNFpxM7R+KZUr6ciAf0wPYK"
            @"04npGZFPGlojwNHYfGFNiUnLGZ7TIfckde+VNRnLHY/Jkubq7EboN0b2dt5xF+dMXwAQPc0QXz1i"
            @"cztSU7oC5x6OyZyPrQHBC+3/Y56RG8heu/wcWVZA7ECUs/CbTFWQuykoR3MP8Bmb0w3A65wzUwPS"
            @"aQGjWCjvPhcG6wwQNjsuaUcInVmdJ2mrpG+4mG2+dCRNWO1Y+C5xobjUhfWSgvZF5XGjeZ2kuW4+"
            @"V0jaKenZAcKgntaPJK3wwduPShp3DQeJsU5I+pakjbnA8FmSXi/p05J2W+y1qTIq6ReSPitpk9Hy"
            @"tF8t6e4BGEJusyTpsKSPhHFD0k0QnbVkL4Jd694rLatU/Zs3AnaRpUDscroF967+Kp5LjbiALFF7"
            @"2DzCc91YKVk8Y4wsNjFKFrd9lCzB+zH3Igcu+XsrcKtLW6DC20FBLMNV9KfAx030s5uI25m2+/6+"
            @"nHhNlOTANMetxyUtkhTZ+G2LtNOjzjYxn291nj3r1Sd240eSlrk5pBUkKLW1hvIPSbcWYVQ0gci+"
            @"D0n6ohPfKiIciH+yYFMwGn6xZQClS58o16Zln5/PzaUKYIclfUHSQkf3lPl1m2DLfV8tabukYzlg"
            @"kj65HfslnWMLi0qAgmvbrVYZY6GkA31yRpIcYEcl3Snpwi5Y9AUuTMB3Wivp65LGchyY58KgTG/q"
            @"RXiSa6B5S8GpmLp5h/KMpK9Jujg3RtfNoqR4+MUvl/QpSX8r2L0T9n3XCwhaHrzdNqcTBZy3V9In"
            @"JJ2f69dXbVT9FQjvU5tH9sMr2yxwMmTPn7ZQ3BMNZl7W8dWtJEvNeJE9P2iu/Z32eWyQ3x+pAlyv"
            @"nwNaTpYReTNZJuQ3G/oJIBp6efdD5q6/y0yLf1HzZ4P+B7A77Q51zFUwAAAAAElFTkSuQmCC";
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        icon = data.length ? [UIImage imageWithData:data scale:3] : nil;
    });
    return icon;
}
