import type { Preview } from "@storybook/react-vite"
import { withThemeByClassName } from "@storybook/addon-themes"
import "./preview.css"

const preview: Preview = {
  parameters: {
    layout: "centered",
    controls: { matchers: { color: /(background|color)$/i } },
    a11y: { test: "error" },
  },
  decorators: [
    withThemeByClassName({ themes: { light: "", dark: "dark" }, defaultTheme: "light" }),
    (Story) => (
      <div className="bg-background text-foreground p-6">
        <Story />
      </div>
    ),
  ],
}

export default preview
