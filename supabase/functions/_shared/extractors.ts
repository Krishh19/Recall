export interface ExtractedContent {
  title: string;
  raw_content: string;
  thumbnail_url?: string;
  platform: 'twitter' | 'instagram' | 'youtube' | 'article';
}

/**
 * Extracts content from Twitter / X URLs using the public oEmbed API.
 */
export async function extractTwitter(url: string): Promise<ExtractedContent> {
  const oembedUrl = `https://publish.x.com/oembed?url=${encodeURIComponent(url)}&omit_script=true`;
  const res = await fetch(oembedUrl);

  if (!res.ok) {
    throw new Error(`Twitter oEmbed returned status ${res.status}`);
  }

  const data = await res.json();
  const html: string = data.html || '';

  // Extract plain text from the returned HTML blockquote
  let tweetText = html
    .replace(/<br\s*[\/]?>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&mdash;.*$/, '')
    .replace(/&[a-z0-9#]+;/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  const authorName: string = data.author_name || 'X User';
  const title = `Post by ${authorName}`;

  if (!tweetText) {
    tweetText = `${title}: ${url}`;
  }

  return {
    title,
    raw_content: tweetText,
    platform: 'twitter',
  };
}

/**
 * Extracts content from Instagram posts using Open Graph meta tags.
 */
export async function extractInstagram(url: string): Promise<ExtractedContent> {
  const res = await fetch(url, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      Accept: 'text/html,application/xhtml+xml',
    },
  });

  if (!res.ok) {
    throw new Error(`Instagram returned status ${res.status}`);
  }

  const html = await res.text();

  const getMeta = (prop: string): string | undefined => {
    const match =
      html.match(new RegExp(`<meta\\s+property=["']${prop}["']\\s+content=["'](.*?)["']`, 'i')) ||
      html.match(new RegExp(`<meta\\s+content=["'](.*?)["']\\s+property=["']${prop}["']`, 'i')) ||
      html.match(new RegExp(`<meta\\s+name=["']${prop}["']\\s+content=["'](.*?)["']`, 'i'));
    return match ? match[1] : undefined;
  };

  const ogTitle = getMeta('og:title');
  const ogDesc = getMeta('og:description') || getMeta('description');
  const ogImage = getMeta('og:image');

  const title = ogTitle || 'Instagram Post';
  const rawContent = ogDesc || 'Instagram photo or video post';

  return {
    title,
    raw_content: rawContent,
    thumbnail_url: ogImage,
    platform: 'instagram',
  };
}

/**
 * Extracts video metadata and transcript from YouTube.
 */
export async function extractYouTube(url: string): Promise<ExtractedContent> {
  let videoId = '';
  const parsed = new URL(url);

  if (parsed.hostname.includes('youtu.be')) {
    videoId = parsed.pathname.replace(/^\//, '');
  } else if (parsed.searchParams.has('v')) {
    videoId = parsed.searchParams.get('v') || '';
  }

  // 1. Fetch metadata via YouTube oEmbed
  let title = 'YouTube Video';
  let authorName = '';
  let thumbnailUrl = videoId ? `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg` : undefined;

  try {
    const oembedRes = await fetch(
      `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`
    );
    if (oembedRes.ok) {
      const data = await oembedRes.json();
      title = data.title || title;
      authorName = data.author_name || '';
      thumbnailUrl = data.thumbnail_url || thumbnailUrl;
    }
  } catch (err) {
    console.warn('YouTube oEmbed fetch error:', err);
  }

  // 2. Fetch transcript via unofficial captions stream
  let transcript = '';
  if (videoId) {
    try {
      const videoPageRes = await fetch(`https://www.youtube.com/watch?v=${videoId}`, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      });

      if (videoPageRes.ok) {
        const pageText = await videoPageRes.text();
        const captionMatch = pageText.match(/"captionTracks":\s*(\[.*?\])/);

        if (captionMatch && captionMatch[1]) {
          const captionTracks = JSON.parse(captionMatch[1]);
          const englishTrack =
            captionTracks.find((t: { languageCode?: string }) => t.languageCode === 'en') ||
            captionTracks[0];

          if (englishTrack && englishTrack.baseUrl) {
            const transcriptRes = await fetch(englishTrack.baseUrl);
            if (transcriptRes.ok) {
              const xml = await transcriptRes.text();
              const textMatches = Array.from(xml.matchAll(/<text[^>]*>([\s\S]*?)<\/text>/gi));
              transcript = textMatches
                .map((m) =>
                  m[1]
                    .replace(/&amp;/g, '&')
                    .replace(/&lt;/g, '<')
                    .replace(/&gt;/g, '>')
                    .replace(/&#39;/g, "'")
                    .replace(/&quot;/g, '"')
                )
                .join(' ')
                .replace(/\s+/g, ' ')
                .trim();
            }
          }
        }
      }
    } catch (err) {
      console.warn('YouTube transcript parsing error:', err);
    }
  }

  const rawContent = transcript
    ? `Video: ${title}\nChannel: ${authorName}\n\nTranscript:\n${transcript}`
    : `Video: ${title}\nChannel: ${authorName}\nURL: ${url}`;

  return {
    title,
    raw_content: rawContent,
    thumbnail_url: thumbnailUrl,
    platform: 'youtube',
  };
}

/**
 * Extracts generic web articles using Jina Reader with robust HTML/OG fallback.
 */
export async function extractArticle(url: string): Promise<ExtractedContent> {
  const jinaUrl = `https://r.jina.ai/${url}`;
  const headers: Record<string, string> = {
    'X-With-Generated-Alt': 'true',
    'X-Return-Format': 'markdown',
  };
  const jinaKey = Deno.env.get('JINA_API_KEY');
  if (jinaKey) {
    headers['Authorization'] = `Bearer ${jinaKey}`;
  }

  try {
    const res = await fetch(jinaUrl, { headers });

    if (res.ok) {
      const markdown = await res.text();

      // Extract title from markdown header (e.g. Title: ... or # ...)
      let title = 'Web Article';
      const titleMatch =
        markdown.match(/^Title:\s*(.+)$/im) ||
        markdown.match(/^#\s+(.+)$/m);

      if (titleMatch) {
        title = titleMatch[1].trim();
      }

      // Extract first image if present
      const imageMatch = markdown.match(/!\[.*?\]\((https?:\/\/[^\s)]+)\)/);
      const thumbnailUrl = imageMatch ? imageMatch[1] : undefined;

      return {
        title,
        raw_content: markdown.trim(),
        thumbnail_url: thumbnailUrl,
        platform: 'article',
      };
    }
  } catch (jinaErr) {
    console.warn('Jina Reader failed, falling back to direct HTML fetch:', jinaErr);
  }

  // Fallback: Direct HTML fetch + Open Graph / meta extraction
  const fallbackRes = await fetch(url, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
    },
  });

  if (!fallbackRes.ok) {
    throw new Error(`Direct page fetch returned status ${fallbackRes.status}`);
  }

  const html = await fallbackRes.text();

  // Extract title
  const ogTitleMatch = html.match(/<meta[^>]*property=["']og:title["'][^>]*content=["']([^"']+)["']/i);
  const titleTagMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i);
  const title = ogTitleMatch?.[1] || titleTagMatch?.[1] || 'Web Article';

  // Extract thumbnail
  const ogImageMatch = html.match(/<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i);
  const thumbnailUrl = ogImageMatch?.[1];

  // Extract description / body text
  const ogDescMatch = html.match(/<meta[^>]*property=["']og:description["'][^>]*content=["']([^"']+)["']/i);
  const metaDescMatch = html.match(/<meta[^>]*name=["']description["'][^>]*content=["']([^"']+)["']/i);
  const description = ogDescMatch?.[1] || metaDescMatch?.[1] || '';

  // Clean body text from HTML
  const cleanedBody = html
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 4000);

  const rawContent = description
    ? `${description}\n\n${cleanedBody}`
    : cleanedBody;

  return {
    title: title.trim(),
    raw_content: rawContent,
    thumbnail_url: thumbnailUrl,
    platform: 'article',
  };
}

/**
 * Router function that detects URL domain and invokes the matching extractor.
 */
export async function extractContent(url: string): Promise<ExtractedContent> {
  const uri = new URL(url);
  const host = uri.hostname.toLowerCase();

  if (
    host === 'x.com' ||
    host.endsWith('.x.com') ||
    host === 'twitter.com' ||
    host.endsWith('.twitter.com') ||
    host === 't.co'
  ) {
    return extractTwitter(url);
  }

  if (
    host === 'instagram.com' ||
    host.endsWith('.instagram.com') ||
    host === 'instagr.am'
  ) {
    return extractInstagram(url);
  }

  if (
    host === 'youtube.com' ||
    host.endsWith('.youtube.com') ||
    host === 'youtu.be'
  ) {
    return extractYouTube(url);
  }

  return extractArticle(url);
}
