# copy qtexternal to $HOME/.config/QtProject/qtcreator/externaltools create it if it doesn't exist
echo "1. Copying qtexternal to $HOME/.config/QtProject/qtcreator/externaltools"
if [ ! -d $HOME/.config/QtProject/qtcreator/externaltools ]; then
    mkdir -p $HOME/.config/QtProject/qtcreator/externaltools
fi

# replace all *.xml file <arguments>путь/что-то.sh</arguments> on <arguments>$(pwd)/scripts/имя_скрипта_xml.sh</arguments>
echo "2. Replacing all *.xml file..."
for file in qtexternal/*.xml; do
    sed -i "s|<arguments>.*</arguments>|<arguments>$(pwd)/scripts/$(basename $file .xml).sh</arguments>|" $file
    echo "    File $file updated"
done

# copy all from qtexternal to $HOME/.config/QtProject/qtcreator/externaltools
echo "3. Copying all from qtexternal to $HOME/.config/QtProject/qtcreator/externaltools"
cp -r qtexternal/* $HOME/.config/QtProject/qtcreator/externaltools

# copy all from snippets to /$HOME/Qt/Tools/QtCreator/share/qtcreator/snippets
echo "4. Copying all from snippets to $HOME/Qt/Tools/QtCreator/share/qtcreator/snippets"
cp -r snippets/* $HOME/Qt/Tools/QtCreator/share/qtcreator/snippets

echo "--------------------------------------------------------------------"
echo "Installation completed successfully."
echo "Please restart Qt Creator to see the changes."