/** Group pictures live in a public Storage bucket, one PNG per group id. */
export function groupPictureUrl(groupId: string) {
  return `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/group-pictures/${groupId}.png`
}
