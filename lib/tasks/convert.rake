# frozen_string_literal: true

desc 'Convert file to PDF test'
task :convert, %i(filename) => %i(environment) do |task, args|
  logger = Rails.logger
  logger.tagged 'Rake Task', 'Convert file to PDF test' do

    unless filename = args[:filename] and File.exist? filename
      logger.warn 'Please provide a valid file name.'
      next # return from task block
    end

    workdir = Rails.root / 'tmp' / SecureRandom.hex
    begin
      workdir.mkdir

      lo_exe = '/Applications/LibreOffice.app/Contents/MacOS/soffice'
      `#{lo_exe} --headless --convert-to odt --outdir #{workdir} #{filename}`

      odt_file = workdir / "#{File.basename filename, '.*'}.odt"
      # entries_dir = workdir / 'contents'
      # entries_dir.mkdir

      `unzip #{odt_file} content.xml -d #{workdir}`

      # Zip::File.open odt_file do |file|
      #   file.each do |entry|
      #     File.dirname(entry.name).tap do |subdir|
      #       FileUtils.mkpath(entries_dir / subdir) unless subdir == '.'
      #     end
      #     entry.extract(entries_dir / entry.name)
      #   end
      # end

      content_file = workdir / 'content.xml'
      has_changes = false

      subs = %w(a e i o u).freeze

      doc = Nokogiri::XML content_file.read
      doc.xpath('//*[contains(text(), "software")]').each do |node|
        node.content = node.text.gsub 'soft', 'hard'
        has_changes ||= true
      end

      if has_changes
        content_file.open('w') { content_file.write doc.to_xml }
        `zip -mj #{odt_file} #{content_file}`

        # Zip::File.open odt_file, Zip::File::CREATE do |io|
        #   Dir.glob entries_dir, '*'
        # end
      end

      `#{lo_exe} --headless --convert-to pdf --outdir #{workdir} #{odt_file}`

    ensure
      #FileUtils.rm_rf workdir
    end
  end
end
