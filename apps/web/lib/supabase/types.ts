// Database types for supabase-js. Regenerate after schema changes with:
//   pnpm supabase gen types typescript --local > apps/web/lib/supabase/types.ts
// (hand-written for the first migration; same shape as the generated file)

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: { id: string; display_name: string; avatar_url: string | null; time_zone: string; created_at: string }
        Insert: { id: string; display_name?: string; avatar_url?: string | null; time_zone?: string; created_at?: string }
        Update: { id?: string; display_name?: string; avatar_url?: string | null; time_zone?: string; created_at?: string }
        Relationships: []
      }
      groups: {
        Row: { id: string; name: string; invite_code: string; time_zone: string; created_by: string; created_at: string }
        Insert: { id?: string; name: string; invite_code?: string; time_zone?: string; created_by?: string; created_at?: string }
        Update: { id?: string; name?: string; invite_code?: string; time_zone?: string; created_by?: string; created_at?: string }
        Relationships: []
      }
      group_members: {
        Row: { group_id: string; user_id: string; role: Database["public"]["Enums"]["group_role"]; joined_at: string }
        Insert: { group_id: string; user_id: string; role?: Database["public"]["Enums"]["group_role"]; joined_at?: string }
        Update: { group_id?: string; user_id?: string; role?: Database["public"]["Enums"]["group_role"]; joined_at?: string }
        Relationships: [
          { foreignKeyName: "group_members_group_id_fkey"; columns: ["group_id"]; isOneToOne: false; referencedRelation: "groups"; referencedColumns: ["id"] },
        ]
      }
      daily_steps: {
        Row: { user_id: string; day: string; steps: number; source: string; updated_at: string }
        Insert: { user_id?: string; day: string; steps: number; source?: string; updated_at?: string }
        Update: { user_id?: string; day?: string; steps?: number; source?: string; updated_at?: string }
        Relationships: []
      }
      group_slack_settings: {
        Row: {
          group_id: string
          webhook_url: string
          enabled: boolean
          post_weekday: number
          post_hour: number
          last_posted_week: string | null
          updated_at: string
        }
        Insert: {
          group_id: string
          webhook_url: string
          enabled?: boolean
          post_weekday?: number
          post_hour?: number
          last_posted_week?: string | null
          updated_at?: string
        }
        Update: {
          group_id?: string
          webhook_url?: string
          enabled?: boolean
          post_weekday?: number
          post_hour?: number
          last_posted_week?: string | null
          updated_at?: string
        }
        Relationships: [
          { foreignKeyName: "group_slack_settings_group_id_fkey"; columns: ["group_id"]; isOneToOne: true; referencedRelation: "groups"; referencedColumns: ["id"] },
        ]
      }
    }
    Views: { [_ in never]: never }
    Functions: {
      join_group: { Args: { code: string }; Returns: string }
      group_for_invite: { Args: { code: string }; Returns: { id: string; name: string; member_count: number }[] }
      group_leaderboard: {
        Args: { gid: string; week?: string }
        Returns: { user_id: string; display_name: string; avatar_url: string | null; total_steps: number; rank: number }[]
      }
      week_start: { Args: { tz: string; at?: string }; Returns: string }
    }
    Enums: { group_role: "owner" | "member" }
    CompositeTypes: { [_ in never]: never }
  }
}
