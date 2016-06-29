# frozen_string_literal: true

desc 'Convert file to PDF test'
task :convert, %i(filename) => %i(environment) do |task, args|
  logger = Rails.logger
  logger.tagged 'Rake Task', 'Convert file to PDF test' do

    unless filename = args[:filename] and File.exist? filename
      logger.warn 'Please provide a valid file name.'
      next
    end

    workdir = Rails.root / 'tmp'
    odt_file = workdir / "#{File.basename filename, '.*'}.odt"
    content_file = workdir / 'content.xml'

    lo_exe = '/Applications/LibreOffice.app/Contents/MacOS/soffice'

    begin

      `#{lo_exe} --headless --convert-to odt --outdir #{workdir} #{filename}`
      `unzip #{odt_file} content.xml -d #{workdir}`

      has_changes = false

      subs = %w(a e i o u).freeze
      rsubs = Regexp.new "[#{subs.join ''}]"
      xsubs = subs.map { |text| %Q[contains(text(), "#{text}")] }.join(' or ')

      doc = Nokogiri::XML content_file.read
      doc.xpath("//*[#{xsubs}]").each do |node|
        node.content = node.text.gsub rsubs, 'x'
        has_changes ||= true
      end

      if has_changes
        content_file.open('w') { content_file.write doc.to_xml }
        `zip -mj #{odt_file} #{content_file}`
      end

      `#{lo_exe} --headless --convert-to pdf --outdir #{workdir} #{odt_file}`

    ensure
      FileUtils.rm odt_file     if File.exist? odt_file
      FileUtils.rm content_file if File.exist? content_file
    end
  end
end
