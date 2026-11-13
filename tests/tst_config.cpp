/*
    About: checks Kickoff Nested's configuration schema (applets/kickoff/
    main.xml). The "Show subfolders" setting must exist as a boolean that is
    on by default, so a fresh launcher shows nested subfolders and switching
    it off restores stock Kickoff's flat categories.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

#include <QFile>
#include <QTest>
#include <QXmlStreamReader>

class ConfigTest : public QObject
{
    Q_OBJECT

private:
    struct Entry {
        QString type;
        QString defaultValue;
        bool found = false;
    };

    static Entry findEntry(const QString &name)
    {
        Entry entry;
        QFile file(QStringLiteral(CONFIG_SCHEMA_FILE));
        if (!file.open(QIODevice::ReadOnly)) {
            return entry;
        }
        QXmlStreamReader xml(&file);
        bool inEntry = false;
        while (!xml.atEnd()) {
            xml.readNext();
            if (xml.isStartElement() && xml.name() == QLatin1String("entry")) {
                inEntry = xml.attributes().value(QLatin1String("name")) == name;
                if (inEntry) {
                    entry.found = true;
                    entry.type = xml.attributes().value(QLatin1String("type")).toString();
                }
            } else if (inEntry && xml.isStartElement() && xml.name() == QLatin1String("default")) {
                entry.defaultValue = xml.readElementText().trimmed();
            } else if (xml.isEndElement() && xml.name() == QLatin1String("entry")) {
                inEntry = false;
            }
        }
        return entry;
    }

private Q_SLOTS:
    void showSubfoldersIsBoolOnByDefault()
    {
        const Entry entry = findEntry(QStringLiteral("showSubfolders"));
        QVERIFY2(entry.found, "entry showSubfolders missing in main.xml");
        QCOMPARE(entry.type, QStringLiteral("Bool"));
        QCOMPARE(entry.defaultValue, QStringLiteral("true"));
    }
};

QTEST_GUILESS_MAIN(ConfigTest)

#include "tst_config.moc"
