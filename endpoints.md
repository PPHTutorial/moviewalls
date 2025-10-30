1.Endpoints to get trending movies as HTML
fetch("https://www.themoviedb.org/remote/panel?panel=trending_scroller&group=this-week", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

fetch("https://www.themoviedb.org/remote/panel?panel=trending_scroller&group=today", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

2.Endpoint to get latest trailers as HTML
fetch("https://www.themoviedb.org/remote/panel?panel=trailer_scroller&group=popular", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

fetch("https://www.themoviedb.org/remote/panel?panel=trailer_scroller&group=streaming", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

fetch("https://www.themoviedb.org/remote/panel?panel=trailer_scroller&group=on-tv", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

3.Endpoint to get Popular movies as HTML
fetch("https://www.themoviedb.org/remote/panel?panel=popular_scroller&group=streaming", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

fetch("https://www.themoviedb.org/remote/panel?panel=popular_scroller&group=on-tv", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

fetch("https://www.themoviedb.org/remote/panel?panel=popular_scroller&group=for-rent", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

fetch("https://www.themoviedb.org/remote/panel?panel=popular_scroller&group=in-theatres", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

4.Endpoint to get free to watch as HTML
fetch("https://www.themoviedb.org/remote/panel?panel=free_scroller&group=tv", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});

fetch("https://www.themoviedb.org/remote/panel?panel=free_scroller&group=movie", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/",
  "body": null,
  "method": "GET",
  "mode": "cors",
  "credentials": "include"
});


5.Endpoint to fetch all movies with sorting params
fetch("https://www.themoviedb.org/discover/movie", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/movie",
  "body": "air_date.gte=&air_date.lte=&certification=&certification_country=GH&debug=&first_air_date.gte=&first_air_date.lte=&page=1&primary_release_date.gte=&primary_release_date.lte=&region=&release_date.gte=&release_date.lte=2026-04-30&show_me=everything&sort_by=popularity.desc&vote_average.gte=0&vote_average.lte=10&vote_count.gte=0&watch_region=GH&with_genres=&with_keywords=&with_networks=&with_origin_country=&with_original_language=&with_watch_monetization_types=&with_watch_providers=&with_release_type=&with_runtime.gte=0&with_runtime.lte=400",
  "method": "POST",
  "mode": "cors",
  "credentials": "include"
});

Here sorting body could be as follows:
  "body": "air_date.gte=&air_date.lte=&certification=&certification_country=GH&debug=&first_air_date.gte=&first_air_date.lte=&page=1&primary_release_date.gte=&primary_release_date.lte=&region=&release_date.gte=&release_date.lte=2026-04-30&show_me=everything&sort_by=popularity.desc&vote_average.gte=0&vote_average.lte=10&vote_count.gte=0&watch_region=GH&with_genres=&with_keywords=&with_networks=&with_origin_country=&with_original_language=&with_watch_monetization_types=&with_watch_providers=&with_release_type=&with_runtime.gte=0&with_runtime.lte=400",

  but nust not be restricted to a static watch_region and release_date.lte since various people accross the world would access this application.
  consider each body has both asc and desc

popular:{
      "air_date.gte=&air_date.lte=&certification=&certification_country=GH&debug=&first_air_date.gte=&first_air_date.lte=&page=1&primary_release_date.gte=&primary_release_date.lte=&region=&release_date.gte=&release_date.lte=2026-04-30&show_me=everything&sort_by=popularity.desc&vote_average.gte=0&vote_average.lte=10&vote_count.gte=0&watch_region=GH&with_genres=&with_keywords=&with_networks=&with_origin_country=&with_original_language=&with_watch_monetization_types=&with_watch_providers=&with_release_type=&with_runtime.gte=0&with_runtime.lte=400",
}
top rated:{
    air_date.gte=&air_date.lte=&certification=&certification_country=GH&debug=&first_air_date.gte=&first_air_date.lte=&page=1&primary_release_date.gte=&primary_release_date.lte=&region=&release_date.gte=&release_date.lte=2026-04-30&show_me=everything&sort_by=vote_average.desc&vote_average.gte=0&vote_average.lte=10&vote_count.gte=0&watch_region=GH&with_genres=&with_keywords=&with_networks=&with_origin_country=&with_original_language=&with_watch_monetization_types=&with_watch_providers=&with_release_type=&with_runtime.gte=0&with_runtime.lte=400
}

release date:{
    air_date.gte=&air_date.lte=&certification=&certification_country=GH&debug=&first_air_date.gte=&first_air_date.lte=&page=1&primary_release_date.gte=&primary_release_date.lte=&region=&release_date.gte=&release_date.lte=2026-04-30&show_me=everything&sort_by=primary_release_date.desc&vote_average.gte=0&vote_average.lte=10&vote_count.gte=0&watch_region=GH&with_genres=&with_keywords=&with_networks=&with_origin_country=&with_original_language=&with_watch_monetization_types=&with_watch_providers=&with_release_type=&with_runtime.gte=0&with_runtime.lte=400
}

title:{
    air_date.gte=&air_date.lte=&certification=&certification_country=GH&debug=&first_air_date.gte=&first_air_date.lte=&page=1&primary_release_date.gte=&primary_release_date.lte=&region=&release_date.gte=&release_date.lte=2026-04-30&show_me=everything&sort_by=title.asc&vote_average.gte=0&vote_average.lte=10&vote_count.gte=0&watch_region=GH&with_genres=&with_keywords=&with_networks=&with_origin_country=&with_original_language=&with_watch_monetization_types=&with_watch_providers=&with_release_type=&with_runtime.gte=0&with_runtime.lte=400
}

6.Endpoint to get search movies as HTML
https://www.themoviedb.org/search/movie?query=frozen
this doesn't have a structured fetch request so I suggest you use the prevous search implementation that I told you to delete, yeah reinstate it

7.Endpoint to get upcoming moves as HTML
fetch("https://www.themoviedb.org/discover/movie", {
  "headers": {
    "accept": "text/html, */*; q=0.01",
    "accept-language": "en-US,en;q=0.9",
    "cache-control": "no-cache",
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest"
  },
  "referrer": "https://www.themoviedb.org/movie/upcoming",
  "body": "air_date.gte=&air_date.lte=&certification=&certification_country=GH&debug=&first_air_date.gte=&first_air_date.lte=&page=1&primary_release_date.gte=&primary_release_date.lte=&region=&release_date.gte=2025-10-30&release_date.lte=2025-11-26&show_me=everything&sort_by=popularity.desc&vote_average.gte=0&vote_average.lte=10&vote_count.gte=0&watch_region=GH&with_genres=&with_keywords=&with_networks=&with_origin_country=&with_original_language=&with_watch_monetization_types=&with_watch_providers=&with_release_type=3%7C1%7C4%7C5%7C6&with_runtime.gte=0&with_runtime.lte=400",
  "method": "POST",
  "mode": "cors",
  "credentials": "include"
});

here starting date as release_date.gte, should be the present day this endpoint is being called