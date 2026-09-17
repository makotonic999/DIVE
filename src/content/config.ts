import { defineCollection, z } from 'astro:content';

/**
 * src/content/config.ts
 * コンテンツコレクションのスキーマ定義。
 * chapters/ 配下のMDXファイルのフロントマターを型安全に管理する。
 */
const chaptersCollection = defineCollection({
  type: 'content',
  schema: z.object({
    /** 章タイトル */
    title: z.string(),

    /** サブタイトル（任意） */
    subtitle: z.string().optional(),

    /** 章番号 (1–21) */
    chapter: z.number().int().min(1).max(21),

    /** Part番号 (1–7) */
    part: z.number().int().min(1).max(7),

    /** Part名（例: "物理・電子・論理回路"） */
    partTitle: z.string(),

    /** 章の概要（OGPやメタdescriptionに使用） */
    description: z.string(),

    /** 公開日 */
    publishedAt: z.date(),

    /** 更新日（任意） */
    updatedAt: z.date().optional(),

    /** キーワードタグ（検索・フィルタリング用） */
    tags: z.array(z.string()).default([]),

    /** 難易度インジケーター */
    difficulty: z.enum(['beginner', 'intermediate', 'advanced']).default('intermediate'),

    /** 想定読了時間（分） */
    readingTimeMinutes: z.number().int().positive().optional(),
  }),
});

export const collections = {
  chapters: chaptersCollection,
};
